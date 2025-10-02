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
    @State private var model = CameraModel()

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
                PreviewView()
                    .onAppear {
                        model.onSetPreviewPause(false)
                    }
                    .onDisappear {
                        model.onSetPreviewPause(true)
                    }

                // Top bar
                VStack {
                    CameraTopBar(torch: model.torch) {
                        model.toggleTorch()
                    } onDismiss: {
                        dismiss()
                    }

                    Spacer()

                    // Bottom controls
                    CameraControls(
                        cameraMode: model.cameraMode,
                        isRecording: model.isRecording,
                        onCameraModeChange: { mode in model.cameraMode = mode },
                        onSwitchCaptureDevice: model.onSwitchCaptureDevice,
                        onTakePhoto: model.onTakePhoto,
                        onToggleRecordVideo: model.onToggleRecordVideo
                    )
                    .padding(.bottom, 24)
                }
                .foregroundStyle(.secondary)
            }
            .preferredColorScheme(.dark)
            .task {
                await model.onStart()
            }
            .onDisappear {
                model.onStop()
            }
            .alert(
                "Kamera",
                isPresented: .constant(model.lastError != nil),
                actions: {
                    Button("U redu") { model.lastError = nil }
                },
                message: { Text(model.lastError ?? "") }
            )
            .alert(
                "Pristup odbijen",
                isPresented: $model.showSettingsDialog,
                actions: {
                    SettingsButton {
                        model.showSettingsDialog = false
                        model.photosAlert = false
                    }
                    Button("Kasnije") {
                        if !model.photosAlert {
                            dismiss()
                        }
                        model.photosAlert = false
                        model.showSettingsDialog = false
                    }
                },
                message: { Text(model.unauthorizeMesssage ?? "") }
            )
            .alert(
                "Pristup odbijen",
                isPresented: $model.showRestrictedDialog,
                actions: {
                    Button("OK") {
                        if !model.photosAlert {
                            dismiss()
                        }
                        model.photosAlert = false
                        model.showRestrictedDialog = false
                    }
                },
                message: { Text(model.unauthorizeMesssage ?? "") }
            )
            .navigationDestination(item: $model.photoUrl) { url in
                MediaView(
                    url: url,
                    isVideo: false,
                    onNext: {
                        onPhoto(url)
                        dismiss()
                    },
                    onSave: {
                        model.saveToPhotos()
                    }
                )
            }
            .navigationDestination(item: $model.movieUrl) { url in
                MediaView(
                    url: url,
                    isVideo: true,
                    onNext: {
                        onPhoto(url)
                        dismiss()
                    },
                    onSave: {
                        model.saveToPhotos(isVideo: true)
                    }
                )
            }
            .alert(isPresented: $model.showSavedAlert) {
                Alert(
                    title: Text("Status"),
                    message: Text(model.savedAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .environment(model)
    }
}

private struct MediaView: View {
    let url: URL
    let isVideo: Bool
    let onNext: () -> Void
    let onSave: () -> Void

    var body: some View {
        MediaPreviewView(mediaURL: url, isVideo: isVideo)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: onSave
                    ) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {

                    Button(
                        action: {
                            onNext()
                        }
                    ) {
                        Text("Nastavi")
                    }
                }
            }
    }
}

private struct CameraTopBar: View {
    let torch: AVCaptureDevice.TorchMode
    let onToggleTorch: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 28, weight: .semibold))
                    .padding(8)
            }
            .tint(.white)
            Spacer()
            Button {
                onToggleTorch()
            } label: {
                Image(
                    systemName: {
                        switch torch {
                        case .off:
                            return "bolt.slash.fill"
                        case .on:
                            return "bolt.fill"
                        default:
                            return "bolt.badge.automatic.fill"
                        }
                    }()
                )
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .semibold))
                .padding(8)
            }
            .tint(.white)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private struct CameraControls: View {
    let cameraMode: CameraMode
    let isRecording: Bool
    let onCameraModeChange: (CameraMode) -> Void
    let onSwitchCaptureDevice: () -> Void
    let onTakePhoto: () -> Void
    let onToggleRecordVideo: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            // Mode switch
            HStack(spacing: 12) {
                ModeButton(
                    title: "Foto",
                    active: cameraMode == .photo
                ) { onCameraModeChange(.photo) }
                ModeButton(
                    title: "Video",
                    active: cameraMode == .video
                ) { onCameraModeChange(.video) }
                Spacer()
                Button {
                    onSwitchCaptureDevice()
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
                switch cameraMode {
                case .photo:
                    onTakePhoto()
                case .video:
                    onToggleRecordVideo()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 84, height: 84)
                    Circle()
                        .fill(
                            cameraMode == .video
                                && isRecording
                                ? .red : .white
                        )
                        .frame(width: 64, height: 64)
                        .overlay {
                            if cameraMode == .video
                                && isRecording
                            {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.red)
                                    .frame(width: 28, height: 28)
                            }
                        }
                }
            }
            .padding(.bottom, 24)
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
