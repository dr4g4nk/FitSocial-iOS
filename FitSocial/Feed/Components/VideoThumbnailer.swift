//
//  VideoThumbnailer.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//


import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

enum VideoThumbnailer {
    static func makeThumbnail(url: URL, time: CMTime = CMTime(seconds: 0.1, preferredTimescale: 600)) async -> UIImage? {
        await withCheckedContinuation { cont in
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
                let image = cgImage.map { UIImage(cgImage: $0) }
                cont.resume(returning: image)
            }
        }
    }
}