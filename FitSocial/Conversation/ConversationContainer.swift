//
//  ConversationContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import Foundation
import SwiftData

@MainActor
public class ConversationContainer{
    
    private let apiClient: APIClient
    private let session: UserSession
    private let modelContainer: ModelContainer
    
    private let userRepository: any UserRepository
    
    private let chatApiService: any ChatApiService
    private let chatRepository: any ChatRepository
    
    private let messageRepository: any MessageRepository
    
    init(apiClient: APIClient, session: UserSession, modelContainer: ModelContainer) {
        self.apiClient = apiClient
        self.session = session
        self.modelContainer = modelContainer
        
        let chatApiService = ChatApiServiceImpl(api: apiClient)
        self.chatApiService = chatApiService
        self.chatRepository = ChatRepositoryImpl(apiService: chatApiService, modelContainer: modelContainer)
        
        let messageApiService = MessageApiServiceImpl(api: apiClient)
        self.messageRepository = MessageRepositoryImpl(apiService: messageApiService, modelContainer: modelContainer)
        
        let userApiService = UserApiServiceImpl(api: apiClient)
        self.userRepository = UserRepositoryImpl(apiService: userApiService)
        
    }
    
    func makeChatsViewModel() -> ChatsViewModel {
        ChatsViewModel(repo: self.chatRepository)
    }
    
    func makeChatDetailViewModel(chat: Chat) -> ChatDetailViewModel {
        ChatDetailViewModel(chat: chat, session: session, modelContainer: modelContainer, repo: messageRepository, chatRepo: chatRepository)
    }
    
    func makeChatUserLIstViewModel() -> ChatUserListViewModel {
        ChatUserListViewModel(userRepo: userRepository)
    }
}
