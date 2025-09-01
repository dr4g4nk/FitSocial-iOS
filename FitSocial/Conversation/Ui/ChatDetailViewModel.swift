//
//  ChatDetailViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 28. 8. 2025..
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import Observation

@MainActor
@Observable
final class ChatDetailViewModel {
    private let repo: any MessageRepository
    private let chatRepo: any ChatRepository
    private let session: UserSession
    private(set) var chat: Chat

    private var page: Int = 0
    private var size: Int = 20
    private var sort: String? = "id,Desc"

    private var noMoreData: Bool = false

    var isLoading = false
    var isSending = false
    var errorMessage: String? = nil
    var messages: [MessageUi] = []
    var draft: String = "" {
        didSet { updateInputState() }
    }
    var showCameraAndAttach: Bool = true

    init(
        chat: Chat,
        session: UserSession,
        repo: any MessageRepository,
        chatRepo: any ChatRepository
    ) {
        self.repo = repo
        self.chatRepo = chatRepo
        self.session = session
        self.chat = chat
    }

    func loadInitial() {
        guard messages.isEmpty else { return }
        Task { await reload() }
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await repo.get(
                chatId: chat.id,
                page: page,
                size: size,
                sort: sort
            )
            messages = data.content.map({ message in
                MessageUi(message: message, status: .sent)
            })
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
                let data = try await repo.get(
                    chatId: chat.id,
                    page: page,
                    size: size,
                    sort: sort
                )
                messages.append(
                    contentsOf: data.content.map({ message in
                        MessageUi(message: message, status: .sent)
                    })
                )
                page = data.number + 1
                noMoreData = data.content.count < size
            } catch {
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
        Task{
            let m = MessageUi(
                message: Message(
                    id: -1,
                    chatId: chat.id,
                    user: await session.user!,
                    content: attacment != nil ? "" : text,
                    label: nil,
                    createdAt: .now,
                    updatedAt: .now,
                    my: true
                ),
                status: .sending(progress: 0.0),
                attachment: attacment != nil
                ? AttacmentUi(
                    filename: attacment!.filename,
                    kind: attacment!.kind
                ) : nil
            )
            
            do {
                messages.insert(m, at: 0)
                
                scrollToId = m.id
                
                if self.chat.id > -1 {
                    let message = try await repo.create(
                        message: MessageDto(chatId: chat.id, content: text),
                        attachment: attacment
                    ) { [self] sent, total, fraction in
                        messages = messages.map({ mes in
                            if mes.id == m.id {
                                return mes.copy({ m in
                                    m.status = .sending(progress: fraction)
                                })
                            }
                            
                            return mes
                        })
                    }
                    if let message = message {
                        messages.removeAll { mui in
                            mui.id == m.id
                        }
                        messages.insert(
                            MessageUi(message: message, status: .sent),
                            at: 0
                        )
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
                        messages = messages.map({ mes in
                            if mes.id == m.id {
                                return mes.copy({ m in
                                    m.status = .sending(progress: fraction)
                                })
                            }
                            
                            return mes
                        })
                    }
                    
                    if data.success {
                        chat = data.result!.copy({ _ in })
                        await reload()
                    } else {
                        errorMessage = data.message
                    }
                }
                draft = ""
            } catch {
                messages = messages.map({ mes in
                    if mes.id == m.id {
                        return mes.copy({ m in
                            m.status = .failed(
                                error: "Nije poslano. Pokušaj ponovo."
                            )
                        })
                    }
                    
                    return mes
                })
                
                errorMessage = error.localizedDescription
            }
            if attacment == nil {
                isSending = false
            }
            else {
                switch attacment!.kind {
                case .image(_, let url), .video(let url, _):
                    try? FileManager.default.removeItem(at: url)
                default: break
                }
            }
        }
    }
    
    func tapCamera() {
        // pokreni kameru (prema tvojoj implementaciji)
    }

    var showChooseDialog = false
    var showImporter = false
    func onSelectFiles(urls: [URL]) {
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            let attachment = AttachmentDto(
                filename: url.lastPathComponent,
                contentType: mimeType(for: url) ?? "",
                kind: .document(url)
            )

            send(attacment: attachment)
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
