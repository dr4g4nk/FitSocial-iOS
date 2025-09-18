//
//  DeepLinkHandler.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 9. 2025..
//

import Foundation

enum LinkRoute: Hashable {
    case chat(id: Int)
    case unknown
}

final class DeepLinkRouter {
    static let shared = DeepLinkRouter()
    
    func handle(url: URL) {
        let route = parse(url: url)
        
        switch route {
        case .chat(let id):
            NotificationCenter.default.post(
                name: .openChat,
                object: nil,
                userInfo: ["chatId": id]
            )
        case .unknown:
            break
        }
    }

    func parse(url: URL) -> LinkRoute {
        // Primjeri: fitsocial://chat/86
        guard url.scheme == "fitsocial" else { return .unknown }
        guard let host = url.host() else { return .unknown }
        
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = path.split(separator: "/").map(String.init)

        guard let first = parts.first?.lowercased() else { return .unknown }
        switch host {
        case "chat":
            guard let id = Int(first) else { return .unknown }
            return .chat(id: id)
        default:
            return .unknown
        }
    }
}
