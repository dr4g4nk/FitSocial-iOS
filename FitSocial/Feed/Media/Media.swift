//
//  Media.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

public struct Media: Identifiable, Codable, Hashable, Copyable {
    public let id: Int
    public let postId: Int
    public let order: Int
    public var url: URL? = nil
    public var mimeType: String? = nil

    public  var isVideo: Bool {
        (mimeType?.hasPrefix("video")) == true
    }

    public var isImage: Bool {
        (mimeType?.hasPrefix("image")) == true
    }

    public func url(isAuthenticated: Bool = true) -> URL? {
        if let url { return url }
        return URL(string: urlString(isAuthenticated: isAuthenticated))
    }
    
    public func urlString(isAuthenticated: Bool = true) -> String {
        let path: String = isAuthenticated
            ? "api/post/media/\(id)/stream"
            : "public/post/media/\(id)/stream"
        return "\(AppConfig.baseURL)\(path)"
    }
}

public struct MediaMultipart: Hashable {
    public let id: Int
    public let postId: Int64
    public let order: Int
    public var uri: URL? = nil
    public var mimeType: String? = nil
    public var fileData: Data? = nil
    public var filename: String? = nil
}
