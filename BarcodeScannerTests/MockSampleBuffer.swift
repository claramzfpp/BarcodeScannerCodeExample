//
//  MockSampleBuffer.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

import SwiftUI
import CoreMedia

class MockSampleBuffer {
    private let brightnessValue: Double?
    private let includeExif: Bool
    private let includeBrightnessKey: Bool
    
    init(
        brightnessValue: Double? = nil,
        includeExif: Bool = true,
        includeBrightnessKey: Bool = true
    ) {
        self.brightnessValue = brightnessValue
        self.includeExif = includeExif
        self.includeBrightnessKey = includeBrightnessKey
    }
    
    func build() throws -> CMSampleBuffer {
        // Create a minimal valid CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            640,
            480,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let imageBuffer = pixelBuffer else {
            throw NSError(
                domain: "MockError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"]
            )
        }
        
        // Create format description
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard let formatDescription = formatDescription else {
            throw NSError(
                domain: "MockError",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create format description"]
            )
        }
        
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(
            duration: CMTimeMake(value: 1, timescale: 30),
            presentationTimeStamp: CMTime.zero,
            decodeTimeStamp: CMTime.invalid
        )
        
        let createStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard createStatus == noErr, let validSampleBuffer = sampleBuffer else {
            throw NSError(
                domain: "MockError",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create sample buffer"]
            )
        }
        
        if includeExif {
            var exifDict: [String: Any] = [:]
            
            if includeBrightnessKey, let brightnessValue = brightnessValue {
                exifDict[kCGImagePropertyExifBrightnessValue as String] = brightnessValue
            }
            
            let attachments = [
                kCGImagePropertyExifDictionary as String: exifDict
            ] as CFDictionary
            
            CMSetAttachments(
                validSampleBuffer,
                attachments: attachments,
                attachmentMode: kCMAttachmentMode_ShouldPropagate
            )
        }
        
        return validSampleBuffer
    }
}
