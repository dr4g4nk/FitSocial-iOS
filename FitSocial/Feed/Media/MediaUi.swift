//
//  Attachment.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import SwiftUI

public struct MediaUi: Identifiable, Equatable, Hashable {
    public enum Kind: Equatable, Hashable {
        case image(Data)
        case video(URL, thumbnail: UIImage?)
        case remoteImage(
            id: Int,
            url: URL,
        )
        case remoteVideo(
            id: Int,
            url: URL,
            thumbnailURL: URL?,
        )
    }
    public let id = UUID()
    public let kind: Kind
    public let mimeType: String?

    public init(kind: Kind, mimeType: String?) {
        self.kind = kind
        self.mimeType = mimeType
    }

    public var accessibilityLabel: String {
        switch kind {
        case .image, .remoteImage: "Slika"
        case .video, .remoteVideo: "Video"
        }
    }

    public var remoteID: Int? {
        switch kind {
        case .remoteImage(let id, _, ), .remoteVideo(let id, _, _): id
        default: nil
        }
    }
}
