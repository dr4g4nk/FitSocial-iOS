//
//  MediaEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftData

@Model
final class MediaEntity : Identifiable {
    @Attribute(.unique) var id: Int
    var postId: Int
    var order: Int
    var url: String
    var mimeType: String?

    init( id: Int,
          postId: Int,
          order: Int,
          url: String,
          mimeType: String? = nil) {
        self.id = id; self.postId = postId; self.order = order; self.url = url; self.mimeType = mimeType
    }
}
