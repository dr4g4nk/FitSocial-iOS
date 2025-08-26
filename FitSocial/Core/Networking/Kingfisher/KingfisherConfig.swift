//
//  KingfisherConfig.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//

import Foundation
import Kingfisher

public enum KingfisherConfig {
    /// Pozovi jednom pri pokretanju aplikacije (npr. u App init-u).
    public static func configure(
        session: UserSession,
        trustedHosts: Set<String> = []
    ) {
        KingfisherManager.shared.defaultOptions = [
            
            .cacheOriginalImage,
            .backgroundDecode,
            .requestModifier(AuthHeaderFieldModifier(session: session))
        ]
    }

    /// Pozovi na logout-u ako želiš “čist start”.
    public static func clearAllCaches() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
}
