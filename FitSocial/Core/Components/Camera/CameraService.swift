//
//  CameraService.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import UIKit

enum CameraPosition { case back, front }

final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()

    // Callbacks
    var onPhotoData: ((Data, String?) -> Void)?
    var onVideoURL: ((URL) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: Permissions
    static func requestPermissions() async -> Bool {
        let videoAuth = await AVCaptureDevice.requestAccess(for: .video)
        let audioAuth = await AVCaptureDevice.requestAccess(for: .audio)
        return videoAuth && audioAuth
    }

    // MARK: Configure
    func configure(
        position: CameraPosition = .back,
        completion: @escaping (Bool) -> Void
    ) {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Clean old
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }

            // Video input
            guard
                let videoDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: position == .back ? .back : .front
                ),
                let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                self.session.canAddInput(videoInput)
            else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.session.addInput(videoInput)
            self.videoInput = videoInput

            // Audio input (for video recording)
            if let audioDevice = AVCaptureDevice.default(for: .audio),
                let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                self.session.canAddInput(audioInput)
            {
                self.session.addInput(audioInput)
                self.audioInput = audioInput
            }

            // Photo
            guard self.session.canAddOutput(self.photoOutput) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.session.addOutput(self.photoOutput)
            //self.photoOutput.maxPhotoDimensions =

            // Movie
            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()
            DispatchQueue.main.async { completion(true) }
        }
    }

    func startRunning() {
        sessionQueue.async {
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stopRunning() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    // MARK: Actions
    func switchCamera(completion: @escaping (Bool) -> Void) {
        sessionQueue.async {
            guard let current = self.videoInput else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.session.beginConfiguration()
            self.session.removeInput(current)

            let newPosition: AVCaptureDevice.Position =
                (current.device.position == .back) ? .front : .back
            guard
                let newDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: newPosition
                ),
                let newInput = try? AVCaptureDeviceInput(device: newDevice),
                self.session.canAddInput(newInput)
            else {
                self.session.addInput(current)
                self.session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.session.addInput(newInput)
            self.videoInput = newInput
            self.session.commitConfiguration()
            DispatchQueue.main.async { completion(true) }
        }
    }

    func setTorch(enabled: Bool) {
        sessionQueue.async {
            guard let device = self.videoInput?.device, device.hasTorch else {
                return
            }
            do {
                try device.lockForConfiguration()
                device.torchMode = enabled ? .on : .off
                device.unlockForConfiguration()
            } catch {}
        }
    }

    var onRunningChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidStart),
            name: AVCaptureSession.didStartRunningNotification,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidStop),
            name: AVCaptureSession.didStopRunningNotification,
            object: session
        )
    }

    @objc private func sessionDidStart() {
        DispatchQueue.main.async { self.onRunningChanged?(true) }
    }
    @objc private func sessionDidStop() {
        DispatchQueue.main.async { self.onRunningChanged?(false) }
    }

    // Je li foto/video konekcija aktivna?
    var isPhotoConnectionActive: Bool {
        session.isRunning
            && (photoOutput.connection(with: .video)?.isEnabled ?? false)
    }
    var isVideoConnectionActive: Bool {
        session.isRunning
            && (movieOutput.connection(with: .video)?.isEnabled ?? false)
    }

    // (opciono) prilagodi preset po modu
    func setMode(_ mode: CameraMode) {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = (mode == .photo) ? .photo : .high
            self.session.commitConfiguration()
        }
    }

    func capturePhoto(flash: AVCaptureDevice.FlashMode = .auto) {
        guard isPhotoConnectionActive else {
            onError?("Kamera još nije spremna")
            return
        }
        let settings = AVCapturePhotoSettings()
        if let device = videoInput?.device, device.isFlashAvailable {
            settings.flashMode = flash
        }
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startRecording() {
        guard isVideoConnectionActive else {
            onError?("Kamera još nije spremna")
            return
        }
        guard !movieOutput.isRecording else { return }
        movieOutput.connection(with: .video)?.videoRotationAngle = 90
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension(
                "mov"
            )
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    func stopRecording() {
        if movieOutput.isRecording { movieOutput.stopRecording() }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func mimeType(from photo: AVCapturePhoto) -> String? {
        guard let data = photo.fileDataRepresentation() else {
            return nil
        }
        return mimeType(fromImageData: data)
    }

    func mimeType(fromImageData data: Data) -> String? {
        guard
            let src = CGImageSourceCreateWithData(data as CFData, nil),
            let typeId = CGImageSourceGetType(src) as String?,
            let ut = UTType(typeId),
            let mime = ut.preferredMIMEType
        else {
            return nil
        }
        return mime // npr. "image/heic" ili "image/jpeg"
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            onError?("Foto greška: \(error.localizedDescription)")
            return
        }
        guard let data = photo.fileDataRepresentation() else { return }
        let mime = mimeType(fromImageData: data)
        onPhotoData?(data, mime)
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error {
            onError?("Video greška: \(error.localizedDescription)")
            return
        }
        onVideoURL?(outputFileURL)
    }
}
