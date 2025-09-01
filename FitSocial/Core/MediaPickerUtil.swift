//
//  MediaPickerUtil.swift
//  FitSocial
//
//  Created by Dragan Kos on 30. 8. 2025..
//

import CoreTransferable
import Foundation
import PhotosUI
import UniformTypeIdentifiers

public struct PickedVideo: Transferable {
    public let url: URL
    public let filename: String
    public let mimeType: String?

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let src = received.file
            let values = try src.resourceValues(forKeys: [.contentTypeKey])
            let type = values.contentType ?? .movie

            let ext = type.preferredFilenameExtension ?? "mov"

            let base = (src.deletingPathExtension().lastPathComponent)
            let filename = "\(base).\(ext)"

            // Naš sandbox copy (npr. /tmp)
            let dst = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(base)-\(UUID().uuidString).\(ext)")

            do {
                try FileManager.default.moveItem(at: src, to: dst)  // bez duplikata
            } catch {
                try FileManager.default.copyItem(at: src, to: dst)  // privremeno dvije kopije
                try? FileManager.default.removeItem(at: src)  // očisti izvor
            }
            return PickedVideo(
                url: dst,
                filename: filename,
                mimeType: type.preferredMIMEType
            )
        }
    }
}

// (opciono) Transferable za sliku — ako koristiš i fotke
public struct PickedImage: Transferable {
    public let url: URL
    public let filename: String
    public let mimeType: String?

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            let src = received.file

            // Pročitaj UTType iz resourceValues
            let values = try src.resourceValues(forKeys: [.contentTypeKey])
            let type = values.contentType ?? .jpeg

            // Ekstenzija iz UTType
            let ext = type.preferredFilenameExtension ?? "jpg"

            // Generiši ime fajla (može i srcURL.lastPathComponent)
            let base = src.deletingPathExtension().lastPathComponent
            let filename = "\(base).\(ext)"

            // Naša kopija u /tmp
            let dst = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(UUID().uuidString).\(ext)")

            do {
                    try FileManager.default.moveItem(at: src, to: dst)
                } catch {
                    try FileManager.default.copyItem(at: src, to: dst)
                    try? FileManager.default.removeItem(at: src)
                }

            return PickedImage(
                url: dst,
                filename: filename,
                mimeType: type.preferredMIMEType
            )
        }
    }
}
