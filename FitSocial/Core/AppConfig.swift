//
//  AppConfig.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Foundation


enum AppConfig {
    static let urlString = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String
    
    static let baseURL: URL = {
            guard let urlString = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String,
                  let url = URL(string: urlString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))) else {
                fatalError("❌ BASE_URL nije validan URL")
            }
            return url
        }()
}
