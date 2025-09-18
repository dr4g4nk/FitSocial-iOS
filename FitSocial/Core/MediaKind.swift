//
//  MediaKind.swift
//  FitSocial
//
//  Created by Dragan Kos on 29. 8. 2025..
//

import SwiftUI

public enum MediaKind: Equatable, Hashable {
    case image(UIImage?, url: URL)
    case video(URL, thumbnail: URL?)
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
