//
//  UserApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 30. 8. 2025..
//

import Foundation

public protocol UserApiService : APIService<Int, User, User, User> {
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> ApiResponse<Page<User>>

}
extension UserApiService {
    public func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String? = nil) async throws -> ApiResponse<Page<User>>{
        var query: [URLQueryItem] = []
        if let page {
            query.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let size {
            query.append(URLQueryItem(name: "size", value: String(size)))
        }
        if let sort {
            query.append(URLQueryItem(name: "sort", value: String(sort)))
        }
        
        if filterValue != nil {
            query.append(URLQueryItem(name: "value", value: filterValue))
        }
        
        return try await api.get("\(basePath)/filter", query: query, requiresAuth: true)
    }
}

public class UserApiServiceImpl : UserApiService{

    public var api: APIClient
    public var basePath: String
    
    init(api: APIClient, basePath: String = "api/user") {
        self.api = api
        self.basePath = basePath
    }
}
