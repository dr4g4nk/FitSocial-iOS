//
//  CameraCaptureView.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = CameraViewModel()

    @State private var showPreview = false

    var onPhoto: (URL) -> Void
    var onVideo: (URL) -> Void

    init(
        onPhoto: @escaping (URL) -> Void,
        onVideo: @escaping (URL) -> Void,
    ) {
        self.onPhoto = onPhoto
        self.onVideo = onVideo
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()

                if vm.isConfigured {
                    CameraPreviewView(session: vm.service.session)
                        .ignoresSafeArea()
                }

                // Top bar
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 28, weight: .semibold))
                                .padding(8)
                        }
                        .tint(.white)
                        Spacer()
                        Button {
                            vm.toggleTorch()
                        } label: {
                            Image(
                                systemName: vm.torchOn
                                    ? "bolt.fill" : "bolt.slash.fill"
                            )
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .semibold))
                            .padding(8)
                        }
                        .tint(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()

                    // Bottom controls
                    VStack(spacing: 16) {
                        // Mode switch
                        HStack(spacing: 12) {
                            ModeButton(title: "Foto", active: vm.mode == .photo)
                            { vm.setMode(.photo) }
                            ModeButton(
                                title: "Video",
                                active: vm.mode == .video
                            ) { vm.setMode(.video) }
                            Spacer()
                            Button {
                                vm.toggleCamera()
                            } label: {
                                Image(
                                    systemName:
                                        "arrow.triangle.2.circlepath.camera"
                                )
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.thinMaterial, in: Circle())
                            }
                            .tint(.white)
                        }
                        .padding(.horizontal, 16)

                        Button {
                            switch vm.mode {
                            case .photo:
                                vm.takePhoto()
                            case .video:
                                vm.toggleRecord()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.15))
                                    .frame(width: 84, height: 84)
                                Circle()
                                    .fill(
                                        vm.mode == .video && vm.isRecording
                                            ? .red : .white
                                    )
                                    .frame(width: 64, height: 64)
                                    .overlay {
                                        if vm.mode == .video && vm.isRecording {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(.red)
                                                .frame(width: 28, height: 28)
                                        }
                                    }
                            }
                        }
                        .disabled(
                            !(vm.mode == .photo
                                ? vm.isReadyForPhoto : vm.isReadyForVideo)
                        )
                        .padding(.bottom, 24)

                        if !(vm.mode == .photo
                            ? vm.isReadyForPhoto : vm.isReadyForVideo)
                        {
                            ProgressView()
                                .padding()
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    .padding(.bottom, 24)
                }
                .foregroundStyle(.secondary)
            }
            .preferredColorScheme(.dark)
            .onAppear {
                vm.setup()
            }
            .onDisappear { vm.stop() }
            .alert(
                "Kamera",
                isPresented: .constant(vm.lastError != nil),
                actions: {
                    Button("U redu") { vm.lastError = nil }
                },
                message: { Text(vm.lastError ?? "") }
            )
            .alert(
                "Pristup odbijen",
                isPresented: $vm.showPermissionAlert,
                actions: {
                    SettingsButton {
                        vm.showPermissionAlert = false
                    }
                    Button("Kasnije") {
                        if !vm.photosAlert{
                            dismiss()
                        }
                        vm.showPermissionAlert = false
                    }
                },
                message: { Text(vm.unauthorizeMesssage ?? "") }
            )
            .navigationDestination(isPresented: $vm.showMediaPreview) {
                if let url = vm.url {
                    MediaPreviewView(mediaURL: url, isVideo: vm.isVideo)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(
                                    action: {
                                        vm.saveToPhotos()
                                    }
                                ) {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                .disabled(vm.isSaving)
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {

                                Button(
                                    action: {
                                        vm.isVideo ? onVideo(url) : onPhoto(url)
                                        dismiss()
                                    }
                                ) {
                                    Text("Nastavi")
                                }
                            }
                        }
                }
            }
            .alert(isPresented: $vm.showSavedAlert) {
                Alert(
                    title: Text("Status"),
                    message: Text(vm.savedAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

private struct ModeButton: View {
    let title: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
                .overlay {
                    if active { Capsule().stroke(.white, lineWidth: 2) }
                }
        }
        .tint(.white)
    }
}
