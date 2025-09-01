//
//  ChatRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol ChatRepository: Repository<Int, Chat, Chat, Chat> where Service : ChatApiService {

    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Entity>
}

class ChatRepositoryImpl<Service: ChatApiService> : ChatRepository {
    var apiService: Service
    
    init(apiService: Service) {
        self.apiService = apiService
    }
    
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Chat> {
        return try await apiService.getAllFiltered(page: page, size: size, sort: sort, filterValue: filterValue).result
    }
    
}
