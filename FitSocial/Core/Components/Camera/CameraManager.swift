//
//  CameraManager.swift
//  SwiftUIDemo2
//
//  Created by Itsuki on 2024/05/15.
//

import AVFoundation
import UIKit

class CameraManager: NSObject, @unchecked Sendable {
    var onError: ((String) -> Void)?
    var onShowSettingsDialog: ((String) -> Void)?
    var onShowRestrictionDialog: ((String) -> Void)?

    private(set) var isRecording = false

    private let captureSession = AVCaptureSession()

    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieFileOutput: AVCaptureMovieFileOutput?

    // for preview
    private var videoOutput: AVCaptureVideoDataOutput?
    private var sessionQueue: DispatchQueue!

    // device related
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTrueDepthCamera, .builtInDualCamera,
                .builtInDualWideCamera, .builtInWideAngleCamera,
                .builtInDualWideCamera,
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .front }
    }

    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .back }
    }

    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
        return devices
    }

    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter({ $0.isConnected })
            .filter({ !$0.isSuspended })
    }

    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice = captureDevice else { return }
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }

    var isRunning: Bool {
        captureSession.isRunning
    }

    var isUsingFrontCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return frontCaptureDevices.contains(captureDevice)
    }

    var isUsingBackCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return backCaptureDevices.contains(captureDevice)
    }

    // for capture photo
    private var addToPhotoStream: ((URL) -> Void)?

    lazy var photoStream: AsyncStream<URL> = {
        AsyncStream { continuation in
            addToPhotoStream = { url in
                continuation.yield(url)
            }
        }
    }()

    // for record movie file
    private var addToMovieFileStream: ((URL) -> Void)?

    lazy var movieFileStream: AsyncStream<URL> = {
        AsyncStream { continuation in
            addToMovieFileStream = { fileUrl in
                continuation.yield(fileUrl)
            }
        }
    }()

    // for preview device output
    var isPreviewPaused = false

    private var addToPreviewStream: ((CIImage) -> Void)?

    lazy var previewStream: AsyncStream<CIImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                if !self.isPreviewPaused {
                    continuation.yield(ciImage)
                }
            }
        }
    }()

    override init() {
        super.init()
        // The value of this property is an AVCaptureSessionPreset indicating the current session preset in use by the receiver. The sessionPreset property may be set while the receiver is running.
        captureSession.sessionPreset = .low

        sessionQueue = DispatchQueue(label: "session queue")
        captureDevice =
            availableCaptureDevices.first
            ?? AVCaptureDevice.default(for: .video)

    }

    func start() async {
        let authorized = await checkAuthorization()
        guard authorized else {
            print("Camera access was not authorized.")
            return
        }
        let micAuth = await checkMicAuthorization()
        guard micAuth else {
            print("Microphone access was not authorized.")
            return
        }

        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return
        }

        sessionQueue.async { [self] in
            self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
    }

    func stop() {
        guard isCaptureSessionConfigured else { return }

        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }

    // switch between available cameras
    func switchCaptureDevice() {
        if let captureDevice = captureDevice,
            let index = availableCaptureDevices.firstIndex(of: captureDevice)
        {
            let nextIndex = (index + 1) % availableCaptureDevices.count
            self.captureDevice = availableCaptureDevices[nextIndex]
        } else {
            self.captureDevice = AVCaptureDevice.default(for: .video)
        }
    }

    private(set) var torch: AVCaptureDevice.TorchMode = .off
    var onTorchModeChanged: ((AVCaptureDevice.TorchMode)->Void)?
    func toggleTorch() {
        sessionQueue.async {
            guard let device = self.deviceInput?.device, device.hasTorch else {
                return
            }
            do {
                try device.toggleTorchMode()
                self.torch = device.torchMode
                self.onTorchModeChanged?(self.torch)
            } catch {}
        }
    }

    func startRecordingVideo() {
        guard let movieFileOutput = self.movieFileOutput else {
            print("Cannot find movie file output")
            return
        }

        do {
            let dirUrl = URL.documentsDirectory.appending(
                component: "Movie",
                directoryHint: .isDirectory
            )
            try checkDirectory(dirUrl)
            let url =
                dirUrl
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(
                    "mov"
                )
            movieFileOutput.startRecording(to: url, recordingDelegate: self)
            isRecording = true
        } catch {
            print("Cannot access local file domain")
            onError?(error.localizedDescription)
            isRecording = false
        }
    }

    func stopRecordingVideo() {
        guard let movieFileOutput = self.movieFileOutput else {
            print("Cannot find movie file output")
            return
        }
        movieFileOutput.stopRecording()
        isRecording = false
    }

    func takePhoto() {
        guard let photoOutput = self.photoOutput else { return }

        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()

            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [
                    AVVideoCodecKey: AVVideoCodecType.hevc
                ])
            }

            let isFlashAvailable =
                self.deviceInput?.device.isFlashAvailable ?? false
            photoSettings.flashMode = isFlashAvailable ? .auto : .off
            if let previewPhotoPixelFormatType = photoSettings
                .availablePreviewPhotoPixelFormatTypes.first
            {
                photoSettings.previewPhotoFormat = [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        previewPhotoPixelFormatType
                ]
            }
            photoSettings.photoQualityPrioritization = .balanced

            if let photoOutputVideoConnection = photoOutput.connection(
                with: .video
            ) {
                photoOutputVideoConnection.videoRotationAngle =
                    RotationAngle.portrait.rawValue
            }

            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice)
    {
        guard isCaptureSessionConfigured else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }

        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput),
                captureSession.canAddInput(deviceInput)
            {
                captureSession.addInput(deviceInput)
            }
        }

        updateVideoOutputConnection()
    }

    private func deviceInputFor(device: AVCaptureDevice?)
        -> AVCaptureDeviceInput?
    {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            print(
                "Error getting capture device input: \(error.localizedDescription)"
            )
            return nil
        }
    }

    private func configureCaptureSession(
        completionHandler: (_ success: Bool) -> Void
    ) {

        var success = false

        self.captureSession.beginConfiguration()

        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }

        guard
            let captureDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            print("Failed to obtain video input.")
            return
        }

        let movieFileOutput = AVCaptureMovieFileOutput()

        let photoOutput = AVCapturePhotoOutput()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "VideoDataOutputQueue")
        )

        guard captureSession.canAddInput(deviceInput) else {
            print("Unable to add device input to capture session.")
            return
        }
        guard captureSession.canAddOutput(photoOutput) else {
            print("Unable to add photo output to capture session.")
            return
        }
        guard captureSession.canAddOutput(videoOutput) else {
            print("Unable to add video output to capture session.")
            return
        }

        captureSession.addInput(deviceInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        captureSession.addOutput(movieFileOutput)

        self.deviceInput = deviceInput
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
        self.movieFileOutput = movieFileOutput

        photoOutput.maxPhotoQualityPrioritization = .quality

        updateVideoOutputConnection()

        isCaptureSessionConfigured = true

        success = true
    }

    var showSettingsDialog = false
    var showRestrictedDialog = false

    var unauthorizeMesssage: String?

    private func checkMicAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("Microphone access authorized.")
            return true
        case .notDetermined:
            print("Microphone access not determined.")
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .audio)
            if !status {
                onShowSettingsDialog?("Dozvolite mikrofon u Podešavanjima.")
            }
            sessionQueue.resume()
            return status
        case .denied:
            print("Microphone access denied.")
            onShowSettingsDialog?("Dozvolite mikrofon u Podešavanjima.")
            onShowSettingsDialog?("Dozvolite mikrofon u Podešavanjima.")
            return false
        case .restricted:
            print("Microphone access restricted.")
            onShowRestrictionDialog?("Pristup mikrofonu je ograničen.")
            return false
        default:
            return false
        }
    }

    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera access authorized.")
            return true
        case .notDetermined:
            print("Camera access not determined.")
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            if !status {
                onShowSettingsDialog?("Dozvolite kameru u Podešavanjima.")
            }
            sessionQueue.resume()
            return status
        case .denied:
            print("Camera access denied.")
            onShowSettingsDialog?("Dozvolite kameru u Podešavanjima.")
            return false
        case .restricted:
            print("Camera access restricted.")
            onShowRestrictionDialog?("Pristup kameri je ograničen.")
            return false
        default:
            return false
        }
    }

    private func updateVideoOutputConnection() {
        if let videoOutput = videoOutput,
            let videoOutputConnection = videoOutput.connection(with: .video)
        {
            if videoOutputConnection.isVideoMirroringSupported {
                videoOutputConnection.isVideoMirrored =
                    isUsingFrontCaptureDevice
            }
        }
    }

    private func checkDirectory(_ url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {

        func mimeType(from photo: AVCapturePhoto) -> (String, String?)? {
            guard let data = photo.fileDataRepresentation() else {
                return nil
            }
            return mimeType(fromImageData: data)
        }

        func mimeType(fromImageData data: Data) -> (String, String?)? {
            guard
                let src = CGImageSourceCreateWithData(data as CFData, nil),
                let typeId = CGImageSourceGetType(src) as String?,
                let ut = UTType(typeId),
                let mime = ut.preferredMIMEType
            else {
                return nil
            }
            return (mime, ut.preferredFilenameExtension)
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

            do {
                let type = mimeType(fromImageData: data)
                let dirUrl = URL.documentsDirectory.appending(
                    component: "Photos",
                    directoryHint: .isDirectory
                )
                try checkDirectory(dirUrl)
                let url =
                    dirUrl
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(
                        type?.1 ?? "jpg"
                    )
                try data.write(to: url, options: .atomic)

                addToPhotoStream?(url)
            } catch {
                onError?(error.localizedDescription)
            }
        }
    }

}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        connection.videoRotationAngle = RotationAngle.portrait.rawValue
        addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        addToMovieFileStream?(outputFileURL)
    }
}

private enum RotationAngle: CGFloat {
    case portrait = 90
    case portraitUpsideDown = 270
    case landscapeRight = 180
    case landscapeLeft = 0
}

extension AVCaptureDevice.TorchMode {
    /// Sve moguće vrijednosti (redoslijed možeš promijeniti po želji).
        static var orderedCases: [AVCaptureDevice.TorchMode] {
            return [.off, .on, .auto]
        }

        /// Vrati sljedeći podržani mode za dati uređaj (kružni).
        func nextSupported(for device: AVCaptureDevice) -> AVCaptureDevice.TorchMode {
            // filtriraj samo podržane mode-ove
            let supported = Self.orderedCases.filter { device.isTorchModeSupported($0) }
            // ako nijedan nije podržan — vrati trenutni
            guard !supported.isEmpty else { return self }
            // nađi indeks trenutnog (ili default na 0)
            let currentIndex = supported.firstIndex(of: self) ?? 0
            let nextIndex = (currentIndex + 1) % supported.count
            return supported[nextIndex]
        }
}

extension AVCaptureDevice {
    /// Promijeni torchMode na sljedeći podržani (zaključava uređaj i otključava).
    /// Poziva se sa `try` jer `lockForConfiguration()` može baciti error.
    func toggleTorchMode() throws {
        guard hasTorch else { return } // nema torch na uređaju
        let nextMode = self.torchMode.nextSupported(for: self)

        // pokušaj zaključati za konfiguraciju
        try lockForConfiguration()
        defer { unlockForConfiguration() }

        // još jednom provjeri podršku (sigurnosna provjera)
        if isTorchModeSupported(nextMode) {
            self.torchMode = nextMode
        }
    }
}


