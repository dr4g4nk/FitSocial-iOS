//
//  Untitled.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation
import SwiftUI

public struct Message: Identifiable, Codable, Copyable, Hashable{
    public let id: Int
    public let chatId: Int
    public let user: User
    public let content: String
    public let label: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let my: Bool
    public let attachment: Attachment?
    
    init(id: Int, chatId: Int, user: User, content: String, label: String?, createdAt: Date, updatedAt: Date, my: Bool, attachment: Attachment? = nil) {
        self.id = id
        self.chatId = chatId
        self.user = user
        self.content = content
        self.label = label
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.my = my
        self.attachment = attachment
    }
    
    public var chatLabel: String {
        var label: String = ""
        if(attachment != nil){
            if(attachment!.isVideo) { label = "\(user.firstName) šalje video" }
            else if(attachment!.isImage) { label = "\(user.firstName) šalje sliku" }
            else { label = "\(user.firstName) šalje dokument" }
        }
        
        return label
    }
}

public struct MessageDto:Identifiable, Codable, Copyable{
    public let id: Int
    public let chatId: Int
    public let content: String
    public let label: String
    public let attachment: Attachment?
    
    init(id: Int = -1, chatId: Int = -1, content: String = "", label: String = "", attachment: Attachment? = nil) {
        self.id = id
        self.chatId = chatId
        self.content = content
        self.label = label
        self.attachment = attachment
    }
}

public struct Attachment:Identifiable, Codable, Copyable, Hashable{
    public let id: Int
    public let fileName: String
    public let contentType: String
    
    init(id: Int, fileName: String = "", contentType: String = "") {
        self.id = id
        self.fileName = fileName
        self.contentType = contentType
    }
    
    public var isVideo: Bool {
        contentType.starts(with: "video")
    }
    
    public var isImage: Bool {
        contentType.starts(with: "image")
    }
    
    public func getImageUrlString() -> String {
        let path: String = "api/attachment/\(id)/stream\(isVideo ? "?thumbnail=true" : "")"
        return "\(AppConfig.baseURL)\(path)"
    }
    
    public func getUrlString() -> String {
        let path: String = "api/attachment/\(id)/stream"
        return "\(AppConfig.baseURL)\(path)"
    }
}

public enum AttachmentKind: Hashable {
    case image(UIImage?, url: URL)
    case video(URL, thumbnail: UIImage?)
    case document(URL)
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

public struct AttachmentDto: Hashable{
    public let filename: String
    public let contentType: String?
    public let kind: AttachmentKind
}
