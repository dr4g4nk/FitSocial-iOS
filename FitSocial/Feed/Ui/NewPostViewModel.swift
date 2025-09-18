//
//  NewPostViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import AVFoundation
import PhotosUI
import SwiftUI
import Observation

@MainActor
@Observable
final class NewPostViewModel {

    // INPUTS
    var text: String = ""
    var postMedia: [MediaUi] = []
    var isPublic = false

    // LIMITS
    let maxAttachments = 10
    let maxTextLength = 2_000

    // STATE
    var isSaving = false
    var errorMessage: String?

    var showCamera = false

    var canPost: Bool {
        (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !postMedia.isEmpty)
            && !isSaving
            && text.count <= maxTextLength
    }

    private let mode: Mode
    private let repo: any PostRepository
    private var post: Post?
    
    let title: String
    let saveButtonLabel: String
    init(mode: Mode, repo: any PostRepository) {
        self.repo = repo
        self.mode = mode
        
        switch mode {
        case .create:
            self.title = "Nova objava"
            self.saveButtonLabel = "Objavi"
            
            self.text = ""
            self.postMedia = []
            self.post = nil
        case .edit(let post):
            self.title = "Uređivanje"
            self.saveButtonLabel = "Sačuvaj"
            
            self.text = post.content
            self.isPublic = post.isPublic
            self.post = post
            self.postMedia = post.media.sorted(by: { m1, m2 in
                m1.order < m2.order
            }).map { m in
                if m.mimeType != nil && m.mimeType!.starts(with: "video") {
                    return MediaUi(
                        kind: .remoteVideo(
                            id: m.id,
                            url: m.url!,
                            thumbnailURL: m.url!.appending(
                                queryItems: [
                                    URLQueryItem(
                                        name: "thumbnail",
                                        value: "true"
                                    )
                                ]
                            )
                        ),
                        mimeType: m.mimeType
                    )
                } else {
                    return MediaUi(
                        kind: .remoteImage(
                            id: m.id,
                            url: m.url!,
                        ),
                        mimeType: m.mimeType
                    )

                }
            }
        }
    }

    func addPickerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items.prefix(maxAttachments - postMedia.count) {
                if let video = try? await item.loadTransferable(type: PickedVideo.self) {
                    let thumb = await Thumbnailer.makeVideoThumbnail(url: video.url)
                    postMedia.append(
                        .init(filename: video.filename, kind: .video(video.url, thumbnail: thumb), mimeType: video.mimeType)
                    )
                }
                else if let img = try? await item.loadTransferable(type: PickedImage.self)
                {
                    postMedia.append(.init(filename: img.filename, kind: .image(Thumbnailer.downsampleImage(at: img.url), url: img.url), mimeType: img.mimeType))
                }
                
            }
        }
    }

    func appendCameraPhoto(_ url: URL) {
        postMedia.append(.init(kind: .image(nil, url: url), mimeType: mimeType(for: url)))
    }

    func appendCameraVideo(_ url: URL) {
        Task {
            let thumb = await Thumbnailer.makeVideoThumbnail(url: url)
            postMedia.append(.init(kind: .video(url, thumbnail: thumb), mimeType: mimeType(for: url)))
        }
    }

    func remove(_ attachment: MediaUi) {
        postMedia.removeAll { $0.id == attachment.id }
    }
    
    func clear(){
        postMedia = []
        text = ""
        isPublic = false
    }

    func moveAttachment(from sourceID: UUID, to targetID: UUID?) {
        guard
            let fromIndex = postMedia.firstIndex(where: { $0.id == sourceID })
        else { return }
        var toIndex = postMedia.count
        if let targetID,
            let idx = postMedia.firstIndex(where: { $0.id == targetID })
        {
            toIndex = idx
        }
        if fromIndex == toIndex { return }
        let item = postMedia.remove(at: fromIndex)
        postMedia.insert(
            item,
            at: fromIndex < toIndex ? toIndex - 1 : toIndex
        )
    }

    func post(onFinish: @MainActor @escaping () -> Void) {
        guard canPost else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                var dto = PostDto()
                var newMedia: [MediaUi] = []
                var order: [Int] = []
                
                dto.content = self.text
                dto.isPublic = self.isPublic
                
                switch mode {
                case .create:
                    dto.id = -1
                case .edit(let existing):
                    dto.id = existing.id
                }
                
                for (index, item) in postMedia.enumerated() {
                    switch item.kind {
                        
                    case .remoteImage(let id, _), .remoteVideo(let id, _, _):
                        dto.media.append(
                            Media(
                                id: id,
                                postId: dto.id,
                                order: index,
                                mimeType: item.mimeType
                            )
                        )
                        
                    case .image, .video:
                        newMedia.append(item)
                        order.append(index)
                    }
                }
                
                if case .create = mode {
                    _ = try await repo.create(post: dto, media: newMedia)
                }
                else {
                    _ = try await repo.update(id: dto.id, post: dto, newMediaOrder: order, newMedia: newMedia)
                }
                
                await MainActor.run {
                    isSaving = false
                    onFinish()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

enum Mode {
    case create
    case edit(existing: Post)
}
