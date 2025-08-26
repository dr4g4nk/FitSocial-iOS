//
//  CameraViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import SwiftUI

enum CameraMode { case photo, video }

@MainActor
@Observable
final class CameraViewModel {
    let service = CameraService()
    var isConfigured = false
    var isRunning = false
    var mode: CameraMode = .photo
    var position: CameraPosition = .back
    var isRecording = false
    var torchOn = false
    var lastError: String?

    // Output to parent (SwiftUI view using kameru)
    var onPhoto: ((Data, String?) -> Void)?
    var onVideo: ((URL) -> Void)?

    var isReadyForPhoto: Bool { service.isPhotoConnectionActive }
    var isReadyForVideo: Bool { service.isVideoConnectionActive }

    func setup() {
        Task {
            let granted = await CameraService.requestPermissions()
            guard granted else {
                lastError = "Dozvolite kameru/mikrofon u Podešavanjima."
                return
            }

            service.onPhotoData = { [weak self] data, mime in
                guard let self else { return }
                self.onPhoto?(data, mime)
            }
            service.onVideoURL = { [weak self] url in
                self?.onVideo?(url)
                self?.isRecording = false
            }
            service.onError = { [weak self] msg in self?.lastError = msg }
            service.onRunningChanged = { [weak self] running in
                self?.isRunning = running
            }

            service.configure(position: .back) { [weak self] ok in
                guard let self else { return }
                self.isConfigured = ok
                if ok {
                    self.service.setMode(self.mode)  // postavi preset po modu
                    self.start()
                } else {
                    self.lastError =
                        "Kamera nije dostupna (proveri da li si na uređaju)."
                }
            }
        }
    }

    func start() {
        guard isConfigured else { return }
        service.startRunning()
        isRunning = true
    }

    func stop() {
        service.stopRunning()
        isRunning = false
        if isRecording {
            service.stopRecording()
            isRecording = false
        }
    }

    func toggleCamera() {
        service.switchCamera { [weak self] ok in
            if ok {
                self?.position = (self?.position == .back ? .front : .back)
            }
        }
    }

    func takePhoto() { service.capturePhoto() }

    func toggleRecord() {
        if isRecording {
            service.stopRecording()
            isRecording = false
        } else {
            service.startRecording()
            isRecording = true
        }
    }

    func toggleTorch() {
        torchOn.toggle()
        service.setTorch(enabled: torchOn)
    }
    
    func setMode(_ newMode: CameraMode) {
            mode = newMode
            service.setMode(newMode)
        }
}
