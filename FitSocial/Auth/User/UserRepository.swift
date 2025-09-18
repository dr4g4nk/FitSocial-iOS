//
//  UserRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 30. 8. 2025.
//

import Foundation

protocol UserRepository: Repository<Int, User, User, User> where Service : UserApiService {

    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Entity>
}

class UserRepositoryImpl<Service: UserApiService> : UserRepository {
    var apiService: Service
    
    init(apiService: Service) {
        self.apiService = apiService
    }
    
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<User> {
        return try await apiService.getAllFiltered(page: page, size: size, sort: sort, filterValue: filterValue).result
    }
    
}
