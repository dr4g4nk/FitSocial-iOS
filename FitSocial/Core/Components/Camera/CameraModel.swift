//
//  CameraModel.swift
//  SwiftUIDemo2
//
//  Created by Itsuki on 2024/05/18.
//

import AVFoundation
import Observation
import Photos
import SwiftUI

@Observable
@MainActor
class CameraModel {
    private let camera = CameraManager()

    var cameraMode: CameraMode = .photo

    var previewImage: Image?
    var photoUrl: URL?
    var movieUrl: URL?

    var lastError: String?

    var showSettingsDialog = false
    var showRestrictedDialog = false

    var unauthorizeMesssage: String?
    var restrictionMessage: String?

    init() {
        camera.onError = { [weak self] msg in self?.lastError = msg }
        camera.onShowSettingsDialog = { [weak self] msg in
            self?.unauthorizeMesssage = msg
            self?.showSettingsDialog = true
        }
        camera.onShowRestrictionDialog = { [weak self] msg in
            self?.restrictionMessage = msg
            self?.showRestrictedDialog = true
        }

        camera.onTorchModeChanged = { [weak self] mode in
            self?.torch = mode
        }
        Task {
            await handleCameraPreviews()
        }

        Task {
            await handleCameraPhotos()
        }

        Task {
            await handleCameraMovie()
        }

    }

    private(set) var torch: AVCaptureDevice.TorchMode = .off

    func toggleTorch() {
        camera.toggleTorch()
    }

    private(set) var isPreviewPaused: Bool = false

    func onSetPreviewPause(_ bool: Bool) {
        isPreviewPaused = bool
        camera.isPreviewPaused = bool
    }

    private(set) var isRecording: Bool = false

    func onTakePhoto() {
        camera.takePhoto()
    }

    func onToggleRecordVideo() {
        if !isRecording {
            camera.startRecordingVideo()
            isRecording = true
        } else {
            camera.stopRecordingVideo()
            isRecording = false
        }
    }

    func onSwitchCaptureDevice() {
        camera.switchCaptureDevice()
    }

    func onStart() async {
        await camera.start()
    }

    func onStop() {
        camera.stop()
    }

    // for preview camera output
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0.image }

        for await image in imageStream {
            Task { @MainActor in
                previewImage = image
            }
        }
    }

    // for photo token
    func handleCameraPhotos() async {
        let photoUrlStream = camera.photoStream

        for await url in photoUrlStream {
            Task { @MainActor in
                photoUrl = url
            }
        }
    }

    // for movie recorded
    func handleCameraMovie() async {
        let fileUrlStream = camera.movieFileStream

        for await url in fileUrlStream {
            Task { @MainActor in
                movieUrl = url
            }
        }
    }

    var photosAlert = false

    private(set) var isSaving = false

    var showSavedAlert = false
    private(set) var savedAlertMessage = ""

    func saveToPhotos(isVideo: Bool = false) {
        Task {
            let isAuthorized = await checkPhotosAuthorizations()
            if !isAuthorized {
                unauthorizeMesssage =
                    "Za čuvanje fotografija ili videa potrebno je omogućiti pristup Photos aplikaciji u podešavanjima."

                photosAlert = true
                showSettingsDialog = true
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

    private func savePhoto() {
        guard let url = photoUrl else {
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
        guard let url = movieUrl else {
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

extension CIImage {
    fileprivate var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent)
        else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

extension UIImage.Orientation {

    fileprivate init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
