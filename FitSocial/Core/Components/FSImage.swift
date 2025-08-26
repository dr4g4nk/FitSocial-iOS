//
//  FSImage.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//

import Kingfisher
import SwiftUI

public struct FSImage: View {
    @Environment(AuthManager.self) private var auth: AuthManager

    public let url: URL?

    public var options: KingfisherOptionsInfo = []

    public init(
        url: URL?,
        options: KingfisherOptionsInfo = []
    ) {
        self.url = url
        self.options = options
    }

    public var body: some View {
        Group {
            if let url {
                let source = makeSource(
                    url: url,
                    userId: auth.user?.id,
                )
                KFImage(source: source)
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.15)
                            ProgressView()
                        }
                    }
                    .onFailure { error in
                        #if DEBUG
                            print("SecureKFImage failed: \(error)")
                        #endif
                    }
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color.gray.opacity(0.15)
            }
        }
    }

    private func generateCacheKey(_ url: URL, userId: Int?) -> String {
        let bucket = userId.map { "u\($0)" } ?? "anon"
        return "img::\(bucket)::\(url.absoluteString)"
    }

    private func makeSource(url: URL, userId: Int?) -> Source {
        let key = generateCacheKey(url, userId: userId)
        return .network(KF.ImageResource(downloadURL: url, cacheKey: key))
    }

}
