//
//  ContentView.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Kingfisher
import SwiftData
import SwiftUI

enum NavTab: Hashable, CaseIterable {
    case feed, activity, messages, add, profile

    var title: String {
        switch self {
        case .feed: "Feed"
        case .activity: "Aktivnosti"
        case .messages: "Poruke"
        case .add: "Objavi"
        case .profile: "Profil"
        }
    }
    var systemImage: String {
        switch self {
        case .feed: "house"
        case .activity: "bolt.heart"
        case .messages: "bubble.left"
        case .add: "plus.app"
        case .profile: "person"
        }
    }
}

struct FitSocialView: View {
    let container: FitSocialContainer
    @Environment(AuthManager.self) var auth: AuthManager

    @State private var feedContainer: FeedContainer
    @State private var profileContainer: ProfileContainer
    @State private var conversationContainer: ConversationContainer

    @State private var previous: NavTab? = nil
    @State private var selected: NavTab = .feed
    @State private var showLogin = false
    @State private var pendingTab: NavTab?

    // per-tab back stacks
    @State private var feedPath = NavigationPath()
    @State private var activityPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    @State private var loginPath = NavigationPath()

    //viewModels
    @State private var loginViewModel: LoginViewModel
    @State private var registrationViewModel: RegistrationViewModel
    @State private var newPostViewModel: NewPostViewModel

    private struct ActivePost: Identifiable {
        var id: Int
    }

    @State private var activePost: ActivePost? = nil

    @State private var selectedPost: Post? = nil

    init(container: FitSocialContainer) {
        self.container = container
        let feedContainer = container.makeFeedContainer()
        self.feedContainer = feedContainer
        self.profileContainer = container.makeProfileContainer()

        self.conversationContainer = container.makeConversationContainer()

        self.loginViewModel = LoginViewModel(authRepo: container.authRepo)
        self.registrationViewModel = RegistrationViewModel(
            authRepo: container.authRepo
        )

        self.newPostViewModel = feedContainer.makeNewPostViewModel()
    }

    private func onLogout() {
        Task {
            await auth.logout()
            selected = .feed
            previous = nil
        }
    }

    var body: some View {
        let selectionBinding = Binding<NavTab>(
            get: { selected },
            set: { newValue in
                previous = selected
                if needsAuth(tab: newValue) {
                    requireAuth(
                        newTab: newValue,
                        action: { selected = newValue }
                    )
                } else {
                    selected = newValue
                }

            }
        )

        TabView(selection: selectionBinding) {
            NavigationStack(path: $feedPath) {
                FeedScreen(
                    container: feedContainer,
                    onComment: { postId in
                        activePost = ActivePost(id: postId)
                    },
                    onViewProfile: { user in
                        requireAuth(newTab: selected) {
                            feedPath.append(user)
                        }
                    },
                    onEditPost: { post in
                        selectedPost = post
                    }
                )
                .navigationDestination(for: User.self) { user in
                    let vm = feedContainer.makeProfileViewModel(user: user)
                    ProfileView(
                        vm: vm,
                        onComment: { postId in
                            activePost = ActivePost(id: postId)
                        },
                        onEditPost: { post in
                            selectedPost = post
                        }
                    ).navigationTitle("\(user.firstName) \(user.lastName)")
                }
                .navigationTitle("Feed")
                .sheet(
                    item: $activePost,
                    onDismiss: {
                        activePost = nil
                    }
                ) { post in
                    CommentsView(
                        vm: feedContainer.makeCommentViewModel(postId: post.id)
                    )
                }
            }
            .tabItem {
                Label(
                    NavTab.feed.title,
                    systemImage: NavTab.feed.systemImage
                )
            }
            .tag(NavTab.feed)

            // ACTIVITY (public: lokalne/statistike)
            NavigationStack(path: $activityPath) {
                /*    ActivityView(vm: container.makeActivityVM(),
                                 requireAuth: requireAuth)
                        .navigationTitle("Aktivnosti")*/
            }
            .tabItem {
                Label(
                    NavTab.activity.title,
                    systemImage: NavTab.activity.systemImage
                )
            }
            .tag(NavTab.activity)
            // ADD (protected)
            NavigationStack {
                NewPostView(
                    vm: newPostViewModel,
                    onSuccess: {
                        if let prev = previous {
                            selected = prev
                            previous = nil
                        }
                    },
                    onCancel: {
                        if let prev = previous {
                            selected = prev
                            previous = nil
                        }
                    }
                )
            }
            .tabItem {
                Label(NavTab.add.title, systemImage: NavTab.add.systemImage)
            }
            .tag(NavTab.add)

            ConversationScreen(conversationContainer: conversationContainer)
                .tabItem {
                    Label(
                        NavTab.messages.title,
                        systemImage: NavTab.messages.systemImage
                    )
                }
                .tag(NavTab.messages)

            NavigationStack(path: $profilePath) {
                ProfileScreen(
                    container: profileContainer,
                    onEditPost: { post in
                        selectedPost = post
                    }
                )
                .navigationTitle("Profil")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            onLogout()
                        } label: {
                            Image(
                                systemName:
                                    "rectangle.portrait.and.arrow.right"
                            )
                        }
                    }
                }
            }
            .tabItem {
                Label(
                    NavTab.profile.title,
                    systemImage: NavTab.profile.systemImage
                )
            }
            .tag(NavTab.profile)
        }
        .animation(nil, value: showLogin)
        .sheet(isPresented: $showLogin) {
            NavigationStack(path: $loginPath) {
                LoginView(
                    vm: loginViewModel,
                    onLoggedIn: { access, refresh, user in
                        Task {
                            try? await container.auth.didLogin(
                                access: access,
                                refresh: refresh,
                                user: user
                            )
                            if let target = pendingTab {
                                previous = selected
                                selected = target
                                pendingTab = nil
                            }
                            showLogin = false
                        }
                    },
                    onCancel: { showLogin = false },
                    onRegistration: { loginPath.append("registration") }
                )
                .navigationTitle("Prijava")
                .navigationDestination(for: String.self) { route in
                    RegistrationView(
                        vm: registrationViewModel,
                        onSuccess: { loginPath.removeLast() }
                    )
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showLogin = false
                        } label: {
                            Image(
                                systemName:
                                    "xmark.circle"
                            ).accessibilityHint("Otkazi")
                        }
                    }
                }
            }.presentationDetents([.large])
        }
        .sheet(item: $selectedPost) { post in
            NewPostView(
                vm: feedContainer.makeNewPostViewModel(post: post),
                onSuccess: {
                    selectedPost = nil
                },
                onCancel: {
                    selectedPost = nil
                }
            )
        }
    }

    private func needsAuth(tab: NavTab) -> Bool {
        switch tab {
        case .messages, .add, .profile: true
        default: false
        }
    }

    // Helper koji možeš proslijediti u child view-ove za „akcije koje traže login“
    private func requireAuth(newTab: NavTab, action: @escaping () -> Void) {
        if auth.isLoggedIn {
            action()
        } else {
            pendingTab = newTab
            showLogin = true
        }
    }
}

struct FitSocialView_Previews: PreviewProvider {

    static var previews: some View {
        FitSocialView(container: FitSocialContainer())
    }
}
