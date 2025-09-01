//
//  FitSocialContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

// AppContainer.swift
import Foundation
import SwiftData

@MainActor
final class FitSocialContainer {

    let modelContainer: ModelContainer

    let jsonDecoder: JSONDecoder
    let jsonEncoder: JSONEncoder

    let session: UserSession
    let apiClient: APIClient
    let auth: AuthManager

    let authRepo: AuthRepository

    init() {
        let schema = Schema([
            UserDataEntity.self,
            UserEntity.self, PostEntity.self, MediaEntity.self,
            ActivityEntity.self,
        ])

        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let tokenStore = KeychainTokenStore(service: "app.fitsocial")
        let currentUserStore = CurrentUserStoreImpl(
            container: modelContainer
        )
        self.session = UserSession(
            tokenStore: tokenStore,
            currentUserStore: currentUserStore
        )

        KingfisherConfig.configure(session: self.session)

        self.jsonDecoder = JSONDecoder.instantDecoder()
        self.jsonEncoder = JSONEncoder.instantEncoder()

        self.apiClient = APIClient(
            baseURL: AppConfig.baseURL,
            session: session,
            encoder: self.jsonEncoder,
            decoder: self.jsonDecoder
        )
        self.auth = AuthManager(session: session)

        self.authRepo = AuthRepositoryImpl(api: apiClient, session: session)
    }

    func makeFeedContainer() -> FeedContainer {
        FeedContainer(
            apiClient: apiClient,
            session: session,
            modelContext: ModelContext(modelContainer)
        )
    }

    func makeProfileContainer() -> ProfileContainer {
        ProfileContainer(
            apiClient: apiClient,
            session: session,
            modelContext: ModelContext(modelContainer)
        )
    }
    
    func makeConversationContainer() -> ConversationContainer {
        ConversationContainer(apiClient: self.apiClient, session: self.session)
    }
}
