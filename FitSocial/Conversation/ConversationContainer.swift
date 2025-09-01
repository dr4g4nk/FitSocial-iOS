//
//  ConversationContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import Foundation

@MainActor
public class ConversationContainer{
    
    private let apiClient: APIClient
    private let session: UserSession
    
    private let userRepository: any UserRepository
    
    private let chatApiService: any ChatApiService
    private let chatRepository: any ChatRepository
    
    private let messageRepository: any MessageRepository
    
    init(apiClient: APIClient, session: UserSession) {
        self.apiClient = apiClient
        self.session = session
        
        let chatApiService = ChatApiServiceImpl(api: apiClient)
        self.chatApiService = chatApiService
        self.chatRepository = ChatRepositoryImpl(apiService: chatApiService)
        
        let messageApiService = MessageApiServiceImpl(api: apiClient)
        self.messageRepository = MessageRepositoryImpl(apiService: messageApiService)
        
        let userApiService = UserApiServiceImpl(api: apiClient)
        self.userRepository = UserRepositoryImpl(apiService: userApiService)
        
    }
    
    func makeChatsViewModel() -> ChatsViewModel {
        ChatsViewModel(repo: self.chatRepository)
    }
    
    func makeChatDetailViewModel(chat: Chat) -> ChatDetailViewModel {
        ChatDetailViewModel(chat: chat, session: session, repo: messageRepository, chatRepo: chatRepository)
    }
    
    func makeChatUserLIstViewModel() -> ChatUserListViewModel {
        ChatUserListViewModel(userRepo: userRepository)
    }
}
