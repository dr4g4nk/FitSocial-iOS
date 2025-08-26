//
//  Untitled.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Observation
import SwiftUI

struct ChatRowViewModel: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let timeString: String
    let avatarSources: [URL?]  // 1 za direkt, 2 za grupu (maks 2 za red)

    init(chat: Chat, now: Date = .now) {
        self.id = chat.id

        if chat.users.count > 1 {
            self.title = !chat.subject.isEmpty ? chat.subject : "Grupni chat"
            self.avatarSources = chat.users.prefix(2).map { URL(string: $0.avatarUrl(privateAccess: true)) }
        } else {
            let other = chat.users.first!
            self.title = !chat.subject.isEmpty ? chat.subject : "\(other.firstName) \(other.lastName)"
            self.avatarSources = [URL(string: other.avatarUrl(privateAccess: true))]
        }

        if let msg = chat.text {
            self.subtitle = msg
            self.timeString = ChatDateFormatter.shortLabel(
                for: chat.lastMessageTime,
                now: now
            )
        } else {
            self.subtitle = "Nema poruka"
            self.timeString = ""
        }
    }
}

// MARK: - Glavni ViewModel

@MainActor
@Observable
final class ChatListViewModel {
    // Ulazni podaci (npr. iz repozitorija / mreže)
    var chats: [Chat] = []

    // UI state
    var searchText: String = ""

    // Derivirani podaci za prikaz
    var rows: [ChatRowViewModel] {
        let mapped = chats.map { ChatRowViewModel(chat: $0) }
        guard
            !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return mapped
        }
        let q = searchText.lowercased()
        return mapped.filter {
            $0.title.lowercased().contains(q)
                || $0.subtitle.lowercased().contains(q)
        }
    }

    // Primjer učitavanja (stub)
    func loadSample() {
        let luka = User(id: 1, firstName: "Luka", lastName: "Perić")
        let ana = User(id: 2,  firstName: "Ana", lastName: "Marić")
        let ema = User(id: 3,  firstName: "Ema", lastName: "Kovač")

        chats = [
            Chat(id: 1, subject: "", text: "dgsdfg s dgre", lastMessageTime: .now, users: [luka]),
            Chat(id: 2, subject: "", text: "dgsdfg s dgre", lastMessageTime: .now, users: [ema, ana]),
        ]
    }
}

// MARK: - Pogled: Lista chatova

struct ChatListScreen: View {
    @State private var vm: ChatListViewModel

    // Callback pri odabiru reda (ako ti treba navigacija)
    var onSelect: (Int) -> Void = { _ in }

    init(
        onSelect: @escaping (Int) -> Void = { _ in }
    ) {
        _vm = State(initialValue: ChatListViewModel())
        
        vm.loadSample()
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fiksni “Search” odmah ispod naslova – jasno, pristupačno,
                // u skladu s HIG (primarni unos je prepoznatljiv i lako dohvatljiv)
                SearchField(text: $vm.searchText, placeholder: "Pretraga")
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                List(vm.rows) { row in
                    Button {
                        onSelect(row.id)
                    } label: {
                        ChatRow(row: row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(row.title), \(row.subtitle), \(row.timeString)"
                    )
                }
                .listStyle(.plain)
            }
            .navigationTitle("Poruke")
            .navigationBarTitleDisplayMode(.large)  // HIG: veliki naslov za glavne ekrane
        }
        .onAppear {
            if vm.chats.isEmpty { vm.loadSample() }
        }
    }
}

// MARK: - Red u listi

private struct ChatRow: View {
    let row: ChatRowViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarStack(urls: row.avatarSources)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.headline)  // HIG: istakni primarnu informaciju
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(row.subtitle)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)  // HIG: sekundarni sadržaj tamnijom sekundarnom bojom
            }

            Spacer(minLength: 8)

            // Vrijeme poruke uz desnu ivicu, poravnato gore
            Text(row.timeString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(row.timeString.isEmpty)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

// MARK: - Avatari (1 za direkt, 2 za grupu)

private struct AvatarStack: View {
    let urls: [URL?]  // 1 ili 2

    var body: some View {
        if urls.count <= 1 {
            Avatar(url: urls.first ?? nil)
        } else {
            ZStack {
                Avatar(url: urls[0])
                    .offset(x: 6, y: 6)
                Avatar(url: urls[1])
                    .offset(x: -6, y: -6)
            }
            .frame(width: 44, height: 44)
        }
    }
}

private struct Avatar: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                FSImage(url: url)
            } else {
                Circle().fill(.quaternary)
                    .overlay(
                        Image(systemName: "person.fill").imageScale(.small)
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .accessibilityLabel("Avatar")
    }
}

// MARK: - Search field (vizuelno konzistentan sa iOS-om)

private struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.body)
                .accessibilityLabel("Polje za pretragu")
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .imageScale(.medium)
                        .accessibilityLabel("Obriši pretragu")
                }
            }
        }
        .padding(10)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

// MARK: - Formatiranje vremena u duhu Poruka/Messages

enum ChatDateFormatter {
    static func shortLabel(
        for date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            let f = DateFormatter()
            f.timeStyle = .short
            f.dateStyle = .none
            return f.string(from: date)
        }
        if let days = calendar.dateComponents(
            [.day],
            from: dateOnly(date, calendar),
            to: dateOnly(now, calendar)
        ).day, days < 7 {
            let f = DateFormatter()
            f.setLocalizedDateFormatFromTemplate("EEE")  // npr. "Pon", "Uto"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }

    private static func dateOnly(_ d: Date, _ cal: Calendar) -> Date {
        cal.startOfDay(for: d)
    }
}

// MARK: - Pregledi

#Preview("Chat lista") {
    return ChatListScreen()
}
