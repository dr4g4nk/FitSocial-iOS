//
//  MediaEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftData
import Foundation

@Model
final class MediaEntity : Identifiable, Hashable {
    @Attribute(.unique) var id: Int
    var postId: Int
    var order: Int
    var url: String
    var mimeType: String?

    init(id: Int,
          postId: Int,
          order: Int,
          url: String,
          mimeType: String? = nil) {
        self.id = id; self.postId = postId; self.order = order; self.url = url; self.mimeType = mimeType
    }
}

extension MediaEntity {
    func toDomain() -> Media {
        Media(id: id, postId: postId, order: order, url: URL(string: url), mimeType: mimeType)
    }
    
    static func fromDomain(_ m: Media, isAuthenticated: Bool = true) -> MediaEntity{
        MediaEntity(id: m.id, postId: m.postId, order: m.order, url: m.urlString(isAuthenticated: isAuthenticated), mimeType: m.mimeType)
    }
}
