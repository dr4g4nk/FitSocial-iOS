//
//  CameraCaptureView.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import SwiftUI

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = CameraViewModel()

    // Public callbacks (reusable u drugim screen-ovima)
    var onPhoto: (Data, String?) -> Void
    var onVideo: (URL) -> Void

    init(onPhoto: @escaping (Data, String?) -> Void,
         onVideo: @escaping (URL) -> Void) {
        self.onPhoto = onPhoto
        self.onVideo = onVideo
    }

    var body: some View {
        ZStack {
            if vm.isConfigured {
                CameraPreviewView(session: vm.service.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Top bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .padding(8)
                    }
                    .tint(.white)
                    Spacer()
                    Button {
                        vm.toggleTorch()
                    } label: {
                        Image(systemName: vm.torchOn ? "bolt.fill" : "bolt.slash.fill")
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
                        ModeButton(title: "Foto",  active: vm.mode == .photo) { vm.setMode(.photo) }
                        ModeButton(title: "Video", active: vm.mode == .video) { vm.setMode(.video) }
                        Spacer()
                        Button {
                            vm.toggleCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 22, weight: .semibold))
                                .padding(10)
                                .background(.thinMaterial, in: Circle())
                        }
                        .tint(.white)
                    }
                    .padding(.horizontal, 16)

                    // Shutter / Record
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
                                .fill(vm.mode == .video && vm.isRecording ? .red : .white)
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
                    .disabled(!(vm.mode == .photo ? vm.isReadyForPhoto : vm.isReadyForVideo))
                    .padding(.bottom, 24)
                    
                    if !(vm.mode == .photo ? vm.isReadyForPhoto : vm.isReadyForVideo) {
                        ProgressView("Inicijalizacija kamere…")
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 12)
                    }
                }
                .padding(.bottom, 24)
            }
            .foregroundStyle(.white)
        }
        .onAppear {
            vm.onPhoto = { [dismiss] data, mimeType in
                onPhoto(data, mimeType)
                dismiss()
            }
            vm.onVideo = { [dismiss] url in
                onVideo(url)
                dismiss()
            }
            vm.setup()
        }
        .onDisappear { vm.stop() }
        .alert("Kamera", isPresented: .constant(vm.lastError != nil), actions: {
            Button("U redu") { vm.lastError = nil }
        }, message: { Text(vm.lastError ?? "") })
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
