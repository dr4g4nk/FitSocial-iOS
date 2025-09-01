import SwiftUI

@MainActor
@Observable
final class ChatDetailViewModel {
    private let repo: any MessageRepository
    private let chatId: Int
    
    var isLoading = false
    var isSending = false
    var errorMessage: String? = nil
    var messages: [Message] = []
    var draft: String = "" {
        didSet { updateInputState() }
    }
    var showCameraAndAttach: Bool = true
    
    init(chatId: Int, repo: any MessageRepository) {
        self.chatId = chatId
        self.repo = repo
    }
    
    func loadInitial() {
        guard messages.isEmpty else { return }
        Task { await reload() }
    }
    
    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            messages = try await repo.get(chatId: chatId)
        } catch {
            errorMessage = "Greška pri učitavanju poruka."
        }
        isLoading = false
    }
    
    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        defer { isSending = false }
        do {
            let m = try await repo.send(chatId: chatId, text: text)
            messages.append(m)
            draft = ""
        } catch {
            errorMessage = "Nije poslano. Pokušaj ponovo."
        }
    }
    
    func tapCamera() {
        // pokreni kameru (prema tvojoj implementaciji)
    }
    
    func tapAttach() {
        // otvori picker za slike/video/dokumente
    }
    
    private func updateInputState() {
        let empty = draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        showCameraAndAttach = empty
    }
}