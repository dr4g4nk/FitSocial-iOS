//
//  MessageUi.swift
//  FitSocial
//
//  Created by Dragan Kos on 29. 8. 2025..
//

import Foundation

struct MessageUi: Identifiable, Hashable, Copyable {
    var id: String {
        messageId > 0 ?  "srv-\(messageId)"  : "tmp-\(localId.uuidString)"
    }
    let localId: UUID
    let messageId: Int
    let chatId: Int
    let user: User
    let content: String
    let label: String?
    let createdAt: Date
    let updatedAt: Date
    let my: Bool
    var status: MessageUiStatus
    private(set) var attachment: AttacmentUi?

    init(localId: UUID = UUID(), message: Message, status: MessageUiStatus, attachment: AttacmentUi? = nil) {
        self.localId = localId
        self.messageId = message.id
        self.chatId = message.chatId
        self.user = message.user
        self.content = message.content
        self.label = message.label
        self.createdAt = message.createdAt
        self.updatedAt = message.updatedAt
        self.my = message.my
        self.status = status
        self.attachment = attachment
        
        if attachment == nil && message.attachment != nil {
            if let url = URL(string: message.attachment!.getUrlString()){
                var kind: AttachmentKind = .document(url)
                
                if message.attachment!.isImage {
                    kind = .remoteImage(id: message.attachment!.id, url: url)
                }
                else if message.attachment!.isVideo {
                    kind = .remoteVideo(id: message.attachment!.id, url: url, thumbnailURL: URL(string: message.attachment!.getImageUrlString()))
                }
                
                self.attachment = AttacmentUi(id: "\(message.attachment!.id)", filename: message.attachment?.fileName ?? "", kind: kind)
            }
        }
    }
}

struct AttacmentUi : Identifiable, Hashable, Copyable {
    var id : String
    let filename: String
    let kind: AttachmentKind
    
    init(id: String = UUID().uuidString, filename: String, kind: AttachmentKind) {
        self.id = id
        self.filename = filename
        self.kind = kind
    }
}

enum MessageUiStatus: Hashable {
    case sending(progress: Double)
    case sent
    case failed(error: String? = nil)
}
