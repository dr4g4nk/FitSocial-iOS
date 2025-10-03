//
//  ConversationNotificationHandler.swift
//  FitSocial
//
//  Created by Dragan Kos on 8. 9. 2025..
//

import Foundation
import Observation
import SwiftData

@Observable
public class ConversationNotificationHandler {
    private let messageLocalStore: MessageLocalStore
    private let chatLocalStore: ChatLocalStore
    private let context: ModelContext
    public var currentChatId: Int? = nil

    private let decoder: JSONDecoder

    init(modelContainer: ModelContainer, decoder: JSONDecoder) {
        self.context = ModelContext(modelContainer)
        self.chatLocalStore = ChatLocalStore(modelContainer: modelContainer)
        self.messageLocalStore = MessageLocalStore(modelContainer: modelContainer)
        self.decoder = decoder
    }

    public func handle(_ data: String) {
        Task {
            do {
                if let d = data.data(using: .utf8) {
                    let message = try decoder.decode(Message.self, from: d)
                    
                    let entity = MessageEntity.fromDomain(from: message)
                    try await messageLocalStore.create(entity)
                }
            } catch {
                if let decErr = error as? DecodingError {
                    switch decErr {
                    case .typeMismatch(_, let ctx),
                            .valueNotFound(_, let ctx),
                            .keyNotFound(_, let ctx),
                            .dataCorrupted(let ctx):
                        print(
                            "DecodingError:",
                            ctx.codingPath.map(\.stringValue).joined(
                                separator: "."
                            ),
                            ctx.debugDescription
                        )
                    @unknown default:
                        print("DecodingError (unknown):", decErr)
                    }
                } else {
                    print("Greška:", error.localizedDescription)
                }
            }
        }
    }
}
