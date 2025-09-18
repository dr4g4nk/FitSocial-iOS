//
//  VideoThumbnailer.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

enum Thumbnailer {
    static func makeVideoThumbnail(
        url: URL,
        time: CMTime = CMTime(seconds: 0.1, preferredTimescale: 600)
    ) async -> URL? {
        await withCheckedContinuation { cont in
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)])
            { _, cgImage, _, _, _ in

                let image = cgImage.map { UIImage(cgImage: $0) }
                guard let data = image?.jpegData(compressionQuality: 0.8) else {
                    cont.resume(returning: nil)
                    return
                }

                // putanja u Documents direktorijumu
                let fileName = UUID().uuidString + ".jpg"
                let fileURL = URL.temporaryDirectory.appendingPathComponent(
                    fileName
                )

                do {
                    try data.write(to: fileURL)
                    cont.resume(returning: fileURL)
                } catch {
                    print("❌ Greška pri čuvanju thumbnail-a:", error)
                    cont.resume(returning: nil)
                }
            }
        }
    }
    static func downsampleImage(
        at imageURL: URL,
        to pointSize: CGSize = CGSize(width: 600, height: 600),
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let maxDimension = max(pointSize.width, pointSize.height) * scale
        guard let src = CGImageSourceCreateWithURL(imageURL as CFURL, nil)
        else { return nil }

        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension),
        ]

        guard
            let cgThumb = CGImageSourceCreateThumbnailAtIndex(
                src,
                0,
                opts as CFDictionary
            )
        else { return nil }
        return UIImage(cgImage: cgThumb, scale: scale, orientation: .up)
    }
}
