import AVFoundation
import SwiftUI

public enum MediaKind: Equatable, Hashable {
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