//
//  AuthRequestModifier.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//

import Foundation
import Kingfisher


public final class AuthHeaderFieldModifier: AsyncImageDownloadRequestModifier {
    public let onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)?
    
    private let session: UserSession
    
    public init(session: UserSession, onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)? = nil) {
        self.session = session
        self.onDownloadTaskStarted = onDownloadTaskStarted
    }
    
    public func modified(for request: URLRequest) async -> URLRequest? {
    var r = request
        
        if let token = try? await session.readAccessToken() {
            r.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }
    
    return r
  }
}

