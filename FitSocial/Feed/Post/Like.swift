//
//  Like.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 8. 2025..
//

import Foundation

public struct Like: Identifiable, Codable, Hashable {
    public let id: Int
    public let postId: Int
    public let userId: Int
    public let active: Bool
}
