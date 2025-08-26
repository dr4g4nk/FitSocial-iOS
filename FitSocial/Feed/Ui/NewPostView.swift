//
//  NewPostView.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import PhotosUI
import SwiftUI

struct NewPostView: View {
    @Bindable private var vm: NewPostViewModel

    private let onSuccess: () -> Void
    private let onCancel: () -> Void

    init(
        vm: NewPostViewModel,
        onSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.vm = vm
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PostTextSection(text: $vm.text, maxLength: vm.maxTextLength)

                    MediaAddButton(
                        remainingSlots: vm.maxAttachments
                            - vm.postMedia.count,
                        onPick: { items in
                            vm.addPickerItems(items)
                        }
                    )

                    PostMediaList(
                        postMedia: vm.postMedia,
                        onRemove: vm.remove(_:),
                        onMove: vm.moveAttachment(from:to:)
                    )
                }
                .padding(16)
            }
            .navigationTitle(vm.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Otkaži") {
                        onCancel()
                        vm.clear()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.saveButtonLabel) {
                        vm.post {
                            onSuccess()
                            vm.clear()
                        }
                    }
                    .disabled(!vm.canPost)
                    .buttonStyle(.borderedProminent)
                }
            }
            .safeAreaInset(edge: .bottom) {
                MediaPickerBar(
                    remainingSlots: vm.maxAttachments
                        - vm.postMedia.count,
                    onPick: { vm.addPickerItems($0) },
                    onShowCamera: { vm.showCamera = true }
                )
                .sheet(isPresented: $vm.showCamera) {
                    CameraCaptureView(
                        onPhoto: { data, mimeType in
                            vm.appendCameraPhoto(data, mimeType: mimeType)
                        },
                        onVideo: { url in
                            vm.appendCameraVideo(url)
                        }
                    )
                    .ignoresSafeArea()
                }

            }
            .alert(
                "Greška",
                isPresented: .constant(vm.errorMessage != nil),
                actions: {
                    Button("U redu", role: .cancel) { vm.errorMessage = nil }
                },
                message: {
                    Text(vm.errorMessage ?? "")
                }
            )
        }
    }
}

