//
//  Util.swift
//  FitSocial
//
//  Created by Dragan Kos on 25. 8. 2025..
//

import AVFoundation
import PhotosUI
import SwiftUI

public func mimeType(for item: PhotosPickerItem) async -> String? {
    if let utType = item.supportedContentTypes.first {
        return utType.preferredMIMEType
    }
    return nil
}

public func mimeType(for url: URL) -> String? {
    if let type = UTType(filenameExtension: url.pathExtension),
       let mime = type.preferredMIMEType {
        return mime
    }
    return nil    }


public enum Action: Equatable {
    case refresh
    case loadMore
}


public struct ActivePost: Identifiable {
    public var id: Int
}
