//
//  ChatDetailView.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import SwiftData
import SwiftUI

struct ChatDetailView: View {
    @Bindable private var vm: ChatDetailViewModel
    @Query private var messages: [MessageEntity]
    
    @State var chatId : Int

    init(vm: ChatDetailViewModel) {
        self.vm = vm
        chatId = vm.chat.id

        _messages = Query(
            filter: #Predicate { $0.chatId == chatId },
            sort: [SortDescriptor(\MessageEntity.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            MessageListView(messages: messages, onLoadMoreIfNeed: { index in
                if index >= (vm.size + vm.page * vm.size - 4) {
                    vm.loadMore()
                }
            })
            .onChange(of: vm.scrollToId) {
                if let id = vm.scrollToId {
                    withAnimation(.smooth) {
                        proxy.scrollTo(id)
                    }
                }
            }
            .onAppear{
                vm.loadInitial()
            }
        }
        .safeAreaInset(edge: .bottom) {
            MessageInputBar(
                text: $vm.draft,
                showExtras: vm.showCameraAndAttach,
                isSending: vm.isSending,
                onSend: { vm.send() },
                onCamera: { vm.showCamera = true },
                onAttach: { vm.showChooseDialog = true }
            )
        }
        .confirmationDialog("", isPresented: $vm.showChooseDialog) {
            ChooseDialog(onChoosePhoto: { vm.showPhotoPicker = true }, onChooseDocument: {
                vm.showImporter = true
            })
            .padding(.horizontal, 16)
            .presentationDetents([.fraction(0.35), .medium])
            .presentationDragIndicator(.hidden)
        }
        .photosPicker(
            isPresented: $vm.showPhotoPicker,
            selection: $vm.selectedPickerItem,
            maxSelectionCount: vm.maxAttachments,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: vm.selectedPickerItem) {
            vm.onSelectPickerItems()
        }
        .fullScreenCover(isPresented: $vm.showCamera) {
            CameraView(
                onPhoto: { url in
                    vm.onNewPhoto(url)
                },
                onVideo: { url in
                    vm.onNewVideo(url)
                }
            )
        }
        .fileImporter(
            isPresented: $vm.showImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) {
            result in
            switch result {
            case .success(let urls):
                vm.onSelectFiles(urls: urls)
            case .failure(let failure):
                vm.onSelectFilesFailure(failure: failure)
            }
        }
        .toolbar{
            ToolbarItem(placement: .principal){
                HStack{
                    GroupAvatar(users: vm.chat.users, size: 40)
                        .accessibilityHidden(true)
                    Text(vm.chat.display).font(.headline)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
