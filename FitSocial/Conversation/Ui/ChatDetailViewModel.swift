//
//  ChatDetailViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 28. 8. 2025..
//

import Observation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ChatDetailViewModel {
    private let repo: any MessageRepository
    private let chatRepo: any ChatRepository
    private let session: UserSession

    private(set) var chat: Chat

    private(set) var page: Int = 0
    private(set) var size: Int = 30
    private var sort: String? = "id,Desc"
    
    var onNewMessage: ((Message) -> Void)?

    private var noMoreData: Bool = false

    var isLoading = false
    var isSending = false
    var errorMessage: String? = nil
    var draft: String = "" {
        didSet { updateInputState() }
    }
    var showCameraAndAttach: Bool = true
    
    var showCamera: Bool = false

    init(
        chat: Chat,
        session: UserSession,
        modelContainer: ModelContainer,
        repo: any MessageRepository,
        chatRepo: any ChatRepository
    ) {
        self.repo = repo
        self.chatRepo = chatRepo
        self.session = session

        self.chat = chat

        if chat.users.isEmpty {
            Task {
                let data = try? await chatRepo.getById(chat.id)
                if let c = data {
                    self.chat = c
                } else {
                    errorMessage = "Nepostojeca konverzacija"
                }
            }
        }
    }

    func loadInitial() {
        Task { await reload() }
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            page = 0
            let data = try await repo.get(
                chatId: chat.id,
                page: page,
                size: size,
                sort: sort
            )
            
            noMoreData = data.content.count < size
        } catch {
            errorMessage = "Greška pri učitavanju poruka."
        }
        isLoading = false
    }

    func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                page = page + 1
                let data = try await repo.get(
                    chatId: chat.id,
                    page: page,
                    size: size,
                    sort: sort
                )
                noMoreData = data.content.count < size
            } catch {
                print(error.localizedDescription)
                errorMessage = "Greška pri učitavanju poruka."
            }

            isLoading = false
        }
    }

    private(set) var scrollToId: String?

    func send(attacment: AttachmentDto? = nil) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        if attacment == nil {
            guard !text.isEmpty, !isSending else { return }
        }
        if attacment == nil {
            isSending = true
        }
        Task {
            var kind: String
            var urlStr: String?
            var thumbnailUrlStr: String?

            var attEnt: AttachmentEntity?

            if let att = attacment {
                switch att.kind {
                case .image(_, let url):
                    urlStr = url.absoluteString
                    kind = "image"
                case .video(let url, let thummbnail):
                    urlStr = url.absoluteString
                    thumbnailUrlStr = thummbnail?.absoluteString
                    kind = "video"
                case .document(let url):
                    urlStr = url.absoluteString
                    kind = "document"
                default:
                    urlStr = nil
                    kind = "document"
                }

                attEnt = AttachmentEntity(
                    kind: kind,
                    urlString: urlStr,
                    thumbnailURLString: thumbnailUrlStr,
                    filename: att.filename,
                    contentType: att.contentType ?? ""
                )
            }

            let m = MessageEntity(
                chatId: chat.id,
                content: attacment != nil ? "" : text,
                label: nil,
                createdAt: .now,
                updatedAt: .now,
                my: true,
                attachment: attEnt,
                status: "sending",
                progress: 0.0,
            )

            do {
                try await repo.createLocal(message: m)
                
                if self.chat.id > -1 {
                    let message = try await repo.create(
                        message: MessageDto(chatId: chat.id, content: text),
                        attachment: attacment
                    ) { [self] sent, total, fraction in
                        Task{
                            do{
                                try await repo.updateMessageProgress(
                                    id: m.persistentModelID,
                                    progress: fraction
                                )
                            } catch{
                                print(error.localizedDescription)
                            }
                        }
                    }
                    try await repo.deleteLocal(m)
                    if let mess = message {
                        try await repo.createLocal(message: mess)
                        onNewMessage?(mess)
                    }
                } else {
                    let data = try await chatRepo.create(
                        chat: .init(
                            id: chat.id,
                            content: attacment == nil ? text : "",
                            userIds: chat.users.map({ usr in
                                usr.id
                            })
                        ),
                        attachment: attacment
                    ) { [self] sent, total, fraction in
                        Task{
                            do {
                                try await repo.updateMessageProgress(
                                    id: m.persistentModelID,
                                    progress: fraction
                                )
                            } catch{
                                print(error.localizedDescription)
                            }
                        }
                    }

                    if data.success {
                        chat = data.result!.copy({ _ in })
                        await reload()
                        try await repo.deleteLocal(m)
                    } else {
                        errorMessage = data.message
                    }
                }
                draft = ""
            } catch {
                try await repo.updateMessageError(id: m.persistentModelID, error: "Nije poslano. Pokušaj ponovo.")

                errorMessage = error.localizedDescription
            }
            if attacment == nil {
                isSending = false
            } else {
                switch attacment!.kind {
                case .image(_, let url), .video(let url, _):
                    try? FileManager.default.removeItem(at: url)
                default: break
                }
            }
        }
    }

    func onNewPhoto(_ url: URL) {
        sendAttachemntFromUrl(url, kind: .image(nil, url: url))
    }
    
    func onNewVideo(_ url: URL) {
        Task{
            let thumb = await Thumbnailer.makeVideoThumbnail(
                url: url
            )
            sendAttachemntFromUrl(url, kind: .video(url, thumbnail: thumb))
        }
    }
    
    private func sendAttachemntFromUrl(_ url: URL, kind: AttachmentKind){
        let attachment = AttachmentDto(
            filename: url.lastPathComponent,
            contentType: mimeType(for: url) ?? "",
            kind: kind
        )

        send(attacment: attachment)
    }

    var showChooseDialog = false
    var showImporter = false
    func onSelectFiles(urls: [URL]) {
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            sendAttachemntFromUrl(url, kind:.document(url))
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    func onSelectFilesFailure(failure: Error) {
        errorMessage = failure.localizedDescription
    }
    let maxAttachments = 10
    var showPhotoPicker = false
    var selectedPickerItem: [PhotosPickerItem] = []
    func onSelectPickerItems() {
        guard !selectedPickerItem.isEmpty else { return }
        let items = selectedPickerItem
        selectedPickerItem = []
        for item in items {
            Task {
                if let video = try? await item.loadTransferable(
                    type: PickedVideo.self
                ) {
                    let thumb = await Thumbnailer.makeVideoThumbnail(
                        url: video.url
                    )

                    let attachment = AttachmentDto(
                        filename: video.filename,
                        contentType: video.mimeType,
                        kind: .video(video.url, thumbnail: thumb)
                    )
                    send(attacment: attachment)
                } else if let img = try? await item.loadTransferable(
                    type: PickedImage.self
                ) {
                    let attachment = AttachmentDto(
                        filename: img.filename,
                        contentType: img.mimeType,
                        kind: .image(
                            Thumbnailer.downsampleImage(at: img.url),
                            url: img.url
                        )
                    )
                    send(attacment: attachment)
                }
            }
        }
    }

    private func updateInputState() {
        let empty = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        showCameraAndAttach = empty
    }
}
