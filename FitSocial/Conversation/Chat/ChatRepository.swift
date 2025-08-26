//
//  ChatRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol ChatRepository: Repository<Int, Chat, Chat, Chat> where Service : ChatApiService {}

class ChatRepositoryImpl<Service: ChatApiService> : ChatRepository {
    var apiService: Service
    
    init(apiService: Service) {
        self.apiService = apiService
    }
}
