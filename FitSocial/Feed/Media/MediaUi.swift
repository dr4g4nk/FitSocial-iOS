//
//  Attachment.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import SwiftUI

public struct MediaUi: Identifiable, Equatable, Hashable {
    
    public let id:UUID
    public let filename: String
    public let kind: MediaKind
    public let mimeType: String?

    public init(filename: String? = nil, kind: MediaKind, mimeType: String?) {
        let id = UUID()
        self.id = id
        self.filename = filename ?? id.uuidString
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
