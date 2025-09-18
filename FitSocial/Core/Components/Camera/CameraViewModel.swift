//
//  CameraViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import Photos
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

    var unauthorizeMesssage: String?

    var isReadyForPhoto: Bool { service.isPhotoConnectionActive }
    var isReadyForVideo: Bool { service.isVideoConnectionActive }

    var showMediaPreview = false

    private(set) var url: URL?
    private(set) var isVideo = false
    
    var showPermissionAlert = false

    func setup() {
        Task {
            let granted = await CameraService.requestPermissions()
            guard granted else {
                unauthorizeMesssage =
                    "Dozvolite kameru/mikrofon u Podešavanjima."
                photosAlert = false
                showPermissionAlert = true
                return
            }

            service.onPhotoURL = { [weak self] url in
                guard let self else { return }
                isVideo = false
                self.url = url
            }
            service.onVideoURL = { [weak self] url in
                guard let self else { return }
                isVideo = true
                self.url = url
                isRecording = false
            }
            service.onError = { [weak self] msg in self?.lastError = msg }
            service.onRunningChanged = { [weak self] running in
                self?.isRunning = running
            }

            service.configure(position: .back) { [weak self] ok in
                guard let self else { return }
                self.isConfigured = ok
                if ok {
                    self.service.setMode(self.mode)
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
        
        url = nil
    }

    func toggleCamera() {
        service.switchCamera { [weak self] ok in
            if ok {
                self?.position = (self?.position == .back ? .front : .back)
            }
        }
    }

    func takePhoto() {
        url = nil
        service.capturePhoto()
    }

    func toggleRecord() {
        if isRecording {
            service.stopRecording()
            isRecording = false
        } else {
            url = nil
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

    private func checkPhotosAuthorizations() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            print("Photo library access authorized.")
            return true
        case .notDetermined:
            print("Photo library access not determined.")
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                == .authorized
        case .denied:
            print("Photo library access denied.")
            return false
        case .restricted:
            print("Photo library access restricted.")
            return false
        @unknown default:
            return false
        }
    }

    var showSavedAlert = false
    private(set) var savedAlertMessage = ""
    private(set) var isSaving = false
    
    var showSettingsAlert = false
    private(set) var photosAlert = false
    
    func saveToPhotos() {
        Task {
            let isAuthorized = await checkPhotosAuthorizations()
            if !isAuthorized {
                unauthorizeMesssage =
                    "Za čuvanje fotografija ili videa potrebno je omogućiti pristup Photos aplikaciji u podešavanjima."
                
                photosAlert = true
                showPermissionAlert = true
                return
            }
            isSaving = true
            defer { isSaving = false }
            if isVideo {
                saveVideo()
            } else {
                savePhoto()
            }
        }
    }

    private func savePhoto() {
        guard let url = url else {
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(
                atFileURL: url
            )
        }) { [weak self] success, error in
            if success {
                self?.savedAlertMessage =
                    "Fotografija sačuvana u Photos aplikaciji."
            } else {
                self?.savedAlertMessage =
                    "Greška pri čuvanju fotografije: \(error?.localizedDescription ?? "nepoznata greška")"
            }
            self?.isSaving = false
            self?.showSavedAlert = true
        }
    }

    private func saveVideo() {
        guard let url = url else {
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(
                atFileURL: url
            )
        }) { [weak self] success, error in
            if success {
                self?.savedAlertMessage =
                    "Video sačuvan u Photos aplikaciji."
            } else {
                self?.savedAlertMessage =
                    "Greška pri čuvanju videa: \(error?.localizedDescription ?? "nepoznata greška")"
            }
            self?.isSaving = false
            self?.showSavedAlert = true
        }
    }
}
