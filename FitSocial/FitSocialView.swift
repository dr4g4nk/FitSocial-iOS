//
//  ContentView.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Kingfisher
import SwiftData
import SwiftUI

struct FitSocialView: View {
    private var container: FitSocialContainer
    @Environment(AuthManager.self) var auth: AuthManager

    @State private var feedContainer: FeedContainer
    @State private var profileContainer: ProfileContainer
    @State private var conversationContainer: ConversationContainer

    //viewModels
    @State private var loginViewModel: LoginViewModel
    @State private var registrationViewModel: RegistrationViewModel
    @State private var newPostViewModel: NewPostViewModel

    @State private var chatsViewModel: ChatsViewModel
    @State private var chatUserListViewModel: ChatUserListViewModel

    @State private var feedPath = NavigationPath()
    @State private var activityPath = NavigationPath()
    @State private var conversationPath = NavigationPath()
    
    @State private var showSettings = false

    @State private var loginPath = NavigationPath()

    @State private var activePost: ActivePost? = nil
    @State private var selectedPost: Post? = nil
    @State private var isCreating = false
    
    @State private var chatDetailViewModel: ChatDetailViewModel?

    init(container: FitSocialContainer) {
        self.container = container

        let feedContainer = container.makeFeedContainer()
        self.feedContainer = feedContainer
        self.profileContainer = container.makeProfileContainer()

        self.loginViewModel = LoginViewModel(authRepo: container.authRepo)
        self.registrationViewModel = RegistrationViewModel(
            authRepo: container.authRepo
        )

        self.newPostViewModel = feedContainer.makeNewPostViewModel()

        let conversationContainer = container.makeConversationContainer()
        self.conversationContainer = conversationContainer
        self.chatsViewModel = conversationContainer.makeChatsViewModel()
        self.chatUserListViewModel =
            conversationContainer.makeChatUserLIstViewModel()
    }

    @State private var currentTab: NavTab = .feed
    @State private var previousTab: NavTab? = nil
    @State private var showLogin = false
    @State private var showWelcome = false
    @State private var pendingTab: NavTab?

    @State private var currentChatId: Int?

    private func onTabChange(_ newTab: NavTab) {
        previousTab = currentTab
        if needsAuth(tab: newTab) {
            requireAuth(
                newTab: newTab,
                action: { self.currentTab = newTab }
            )
        } else {
            currentTab = newTab
        }
    }

    private func needsAuth(tab: NavTab) -> Bool {
        switch tab {
        case .messages, .add, .profile: true
        default: false
        }
    }

    private func requireAuth(newTab: NavTab, action: @escaping () -> Void) {
        if auth.isLoggedIn {
            action()
        } else {
            pendingTab = newTab
            showLogin = true
        }
    }

    private func onLogout() {
        Task {
            await auth.logout()
            currentTab = .feed
            previousTab = nil
        }
    }

    var body: some View {
        let selectionBinding = Binding<NavTab>(
            get: { currentTab },
            set: { newValue in
                onTabChange(newValue)

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
                        requireAuth(newTab: currentTab) {
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

            NavigationStack(path: $activityPath) {
                ExerciseScreen(container: container)
            }
            .tabItem {
                Label(
                    NavTab.activity.title,
                    systemImage: NavTab.activity.systemImage
                )
            }
            .tag(NavTab.activity)

            NavigationStack {
                NewPostView(
                    vm: newPostViewModel,
                    onSuccess: {
                        if let prev = previousTab {
                            currentTab = prev
                            previousTab = nil
                        }
                    },
                    onCancel: {
                        if let prev = previousTab {
                            currentTab = prev
                            previousTab = nil
                        }
                    }
                )
            }
            .tabItem {
                Label(NavTab.add.title, systemImage: NavTab.add.systemImage)
            }
            .tag(NavTab.add)

            NavigationStack(path: $conversationPath) {
                ChatsView(
                    viewModel: chatsViewModel,
                    onOpenChat: { chat in
                        container.contersationNotificationHandler.currentChatId = chat.id
                        chatDetailViewModel = conversationContainer.makeChatDetailViewModel(chat: chat)
                        conversationPath.append(chat)
                    }
                )
                .navigationTitle("Poruke")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isCreating = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Novi chat")
                    }
                }
                .navigationDestination(for: Chat.self) { chat in
                    ChatDetailView(
                        vm: chatDetailViewModel!
                    )
                    .onDisappear {
                        container.contersationNotificationHandler.currentChatId = nil
                    }
                }
                .sheet(
                    isPresented: $isCreating,
                    onDismiss: { chatUserListViewModel.clear() }
                ) {
                    NavigationStack {
                        ChatUserListView(
                            vm: chatUserListViewModel,
                            onNext: { users in
                                chatsViewModel.create(users: users) { chat in
                                    chatDetailViewModel = conversationContainer.makeChatDetailViewModel(chat: chat)
                                    conversationPath.append(chat)
                                    isCreating = false
                                }
                            }
                        )
                        .navigationTitle("Korisnici")
                        .navigationBarTitleDisplayMode(.large)
                    }
                }
                .navigationBarTitleDisplayMode(.large)
            }.toolbar(
                conversationPath.isEmpty ? .visible : .hidden,
                for: .tabBar
            )
            .tabItem {
                Label(
                    NavTab.messages.title,
                    systemImage: NavTab.messages.systemImage
                )
            }
            .tag(NavTab.messages)

            NavigationStack {
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
                            showSettings = true
                        } label: {
                            Image(
                                systemName:
                                    "ellipsis.circle"
                            )
                        }
                    }
                }
                .navigationDestination(isPresented: $showSettings){
                    SettingsView(onLogout: onLogout)
                        .navigationTitle("Podešavanja")
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
                            try? await auth.didLogin(
                                access: access,
                                refresh: refresh,
                                user: user
                            )
                            if let target = pendingTab {
                                previousTab = currentTab
                                currentTab = target
                                pendingTab = nil
                            }
                            
                            container.notificationManager.checkAuthorization({granted, error in
                                if granted == nil {
                                    showWelcome = true
                                }
                            }, request: false)
                            
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
        .fullScreenCover(isPresented: $showWelcome) {
            NotificationPermissionView {
                container.notificationManager.requestAuthorization()
                showWelcome = false
            } onSkip: {
                showWelcome = false
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .openChat)) {
            note in
            if let chatId = note.userInfo?["chatId"] as? Int {
                if currentTab != .messages {
                    onTabChange(.messages)
                }
                if container.contersationNotificationHandler.currentChatId != chatId {
                    container.contersationNotificationHandler.currentChatId = chatId
                    
                    let chat = Chat(id: chatId)
                    chatDetailViewModel = conversationContainer.makeChatDetailViewModel(chat: chat)
                    conversationPath.append(chat)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exercise)) { _ in
            if currentTab != .activity {
                onTabChange(.activity)
            }
        }
    }

}


public enum NavTab: Hashable, CaseIterable {
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
        case .activity: "figure.run"
        case .messages: "message.fill"
        case .add: "plus.app"
        case .profile: "person"
        }
    }
}


struct FitSocialView_Previews: PreviewProvider {

    static var previews: some View {
        FitSocialView(container: FitSocialContainer())
    }
}
