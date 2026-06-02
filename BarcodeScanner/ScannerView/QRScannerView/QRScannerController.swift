//
//  QRScannerController.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import SwiftUI
public import AVFoundation

/// Controller for scanning and processing QR codes.
/// This is where the video capture is initialized, started, and stopped.
public class QRScannerController: UIViewController {
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    // Use a dedicated serial queue for all capture session operations to prevent thread collision
    private let sessionQueue = DispatchQueue(label: "com.smarthome.qrscanner.sessionQueue")
    private let videoOutputQueue = DispatchQueue(label: "com.smarthome.qrscanner.videoOutput")    
    private let torchManager = TorchManager(turnOnThreshold: -2.0, turnOffThreshold: 3.0)
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
#if targetEnvironment(simulator)
        setupSimulatorView()
#else
        configureSession()
#endif
    }
    
    /// Sets up a placeholder view for the simulator environment since camera access is unavailable.
    /// Displays a centered label indicating that the camera is not available.
    private func setupSimulatorView() {
        view.backgroundColor = .black
        let label = UILabel()
        label.text = "Camera not available on Simulator"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// Configures the AVCaptureSession with video input, metadata output, and video data output.
    ///
    /// All operations are performed on a dedicated serial queue to prevent thread collisions.
    private func configureSession() {
        sessionQueue.async(qos: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let captureDevice: AVCaptureDevice?
            
            captureDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            )

            guard let captureDevice = captureDevice else {
                print("Failed to get the device camera")
                return
            }
            
            // Hardware Configuration (Focus & Auto-Torch)
            hardwareConfiguration(captureDevice)
            
            // I/O Setup
            self.captureSession.beginConfiguration()
            
            // Video Input
            do {
                let videoInput = try AVCaptureDeviceInput(device: captureDevice)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                }
            } catch {
                print("Error creating AVCapture device input: \(error)")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Metadata Output (QR)
            let metadataOutput = AVCaptureMetadataOutput()
            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)
                
                // Delegate must receive callbacks on the main thread for UI updates
                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.dataMatrix, .qr, .code39, .code128]
            }
            
            // Video Data Output (Brightness)
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if self.captureSession.canAddOutput(videoDataOutput) {
                self.captureSession.addOutput(videoDataOutput)
                videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
        
        setupPreviewLayer()
    }
    
    private func hardwareConfiguration(_ captureDevice: AVCaptureDevice) {
        do {
            try captureDevice.lockForConfiguration()
            
            /// Enables continuous auto-focus (camera automatically adjusts focus as you move)
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            }
            
            /// Initialize Torch to OFF so we can control it manually
            if captureDevice.isTorchModeSupported(.off) {
                captureDevice.torchMode = .off
            }
            
            captureDevice.unlockForConfiguration()
        } catch {
            print("Error configuring capture device: \(error)")
        }
    }
    
    /// Sets up the AVCaptureVideoPreviewLayer to display the camera feed.
    /// The preview layer is configured to fill the view while maintaining aspect ratio.
    private func setupPreviewLayer() {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.frame
        view.layer.addSublayer(videoPreviewLayer)
        
        self.videoPreviewLayer = videoPreviewLayer
    }
    
    /// Called when the view controller's view is about to be removed from the view hierarchy.
    /// Stops the capture session to conserve resources.
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
#if !targetEnvironment(simulator)
        sessionQueue.async { [weak self] in
            self?.torchManager.disableTorch()
            self?.torchManager.reset()
            self?.captureSession.stopRunning()
        }
#endif
    }
    
    /// Called when the view controller's view has been added to the view hierarchy.
    /// Resumes the capture session if it was previously stopped.
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
#if !targetEnvironment(simulator)
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession, !session.isRunning else { return }
            session.startRunning()
        }
#endif
    }
    
    /// Called when the view controller's view's bounds change.
    /// Updates the preview layer frame to match the new view size.
    public override func viewDidLayoutSubviews() {
        videoPreviewLayer?.frame = view.frame
        super.viewDidLayoutSubviews()
    }
}

// MARK: - Manual Auto-Torch Logic
/// Extension handling automatic torch control based on ambient brightness.
extension QRScannerController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Processes video frames to monitor ambient brightness and automatically control the torch (device's flashlight)
    ///
    /// The torch is turned ON when brightness falls below 4.0 (typical indoor lighting)
    /// and turned OFF when brightness exceeds 7.0 (bright conditions).
    /// Updates are throttled to occur at most every 2.0 seconds for faster response.
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let device = getCaptureDevice() else { return }
        
        sessionQueue.async { [weak self] in
            self?.torchManager.updateTorch(sampleBuffer, device: device)
        }
    }
    
    /// Retrieves the capture device from the session's inputs.
    private func getCaptureDevice() -> AVCaptureDevice? {
        guard let deviceInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            return nil
        }
        return deviceInput.device
    }
}
