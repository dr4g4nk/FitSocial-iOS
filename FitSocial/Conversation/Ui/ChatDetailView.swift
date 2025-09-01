//
//  ChatDetailView.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import SwiftUI

struct ChatDetailView: View {
    @Bindable private var vm: ChatDetailViewModel

    init(vm: ChatDetailViewModel) {
        self.vm = vm
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.messages) { msg in
                        MessageRow(messageUi: msg)
                            .id(msg.id)
                            .padding(.horizontal, 12)
                            .flippedUpsideDown()
                    }
                    PagingTrigger(onVisible: {
                        if vm.chat.id > -1 {
                            vm.loadMore()
                        }
                    })
                }
                .scrollTargetLayout()
                .padding(.vertical, 8)
            }
            .flippedUpsideDown()
            .onChange(of: vm.scrollToId) {
                if let id = vm.scrollToId {
                    withAnimation(.smooth) {
                        proxy.scrollTo(id)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .onChange(of: vm.chat) {
            old,
            new in
            if old.id == -1 && new.id > -1 {

            }
        }
        .safeAreaInset(edge: .bottom) {
            MessageInputBar(
                text: $vm.draft,
                showExtras: vm.showCameraAndAttach,
                isSending: vm.isSending,
                onSend: { vm.send() },
                onCamera: vm.tapCamera,
                onAttach: { vm.showChooseDialog = true }
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .confirmationDialog("", isPresented: $vm.showChooseDialog) {
            VStack(spacing: 12) {
                Capsule().fill(.tertiary)
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                VStack(spacing: 8) {
                    Button(
                        "Odaberi fotografije",
                        systemImage: "photo",
                        action: { vm.showPhotoPicker = true }
                    )

                    Button(
                        "Odaberi dokumente",
                        systemImage: "doc.text",
                        action: {
                            vm.showImporter = true
                        }
                    )
                }
                .padding(.vertical, 8)

                Spacer(minLength: 0)

                Button("Zatvori", role: .cancel) {}
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .presentationDetents([.fraction(0.35), .medium])  // iOS 16+
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
    }
}
