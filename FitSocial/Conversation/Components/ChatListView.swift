//
//  ChatListView.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import SwiftUI

struct ChatListView: View {
    let chats: [Chat]
    var onOpen: (Chat) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            List(chats) { chat in
                Button {
                    onOpen(chat)
                } label: {
                    ChatRowView(chat: chat)
                }
                .buttonStyle(.plain) // zadržava HIG stil liste
                .contentShape(Rectangle()) // osigurava 44pt tap target
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: chat))
                .accessibilityHint("Otvori konverzaciju")
            }
            .navigationTitle("Chatovi")
        }
    }

    private func accessibilityLabel(for chat: Chat) -> String {
        let dateText = RelativeDateTimeFormatter().localizedString(
            for: chat.lastMessageTime,
            relativeTo: Date(),
        )
        return "\(chat.subject). Posljednja poruka: \(chat.text). \(dateText)."
    }
}

struct ChatRowView: View {
    let chat: Chat
    @Environment(\.dynamicTypeSize) private var typeSize

    private var avatarSize: CGFloat {
        // suptilno povećaj za veće Dynamic Type veličine
        switch typeSize {
        case let s where s < .xLarge: return 48
        case .xLarge:    return 52
        default:         return 56
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            avatarGroup
                .frame(width: avatarSize, height: avatarSize)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(chat.subject)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(timeString(for: chat.lastMessageTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }

                Text(chat.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 8) // udoban vertikalni ritam
    }

    @ViewBuilder
    private var avatarGroup: some View {
        if chat.users.count == 1 {
            AvatarView(user: chat.users.first!, size: avatarSize)
        }
        else {
            GroupAvatarView(
                primary: chat.users.first,
                secondary: chat.users.dropFirst().first,
                size: avatarSize
            )
        }
    }

    private func timeString(for date: Date) -> String {
        // Ako je danas — prikaži vrijeme; inače relativno (juče, prije 2 dana…)
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.doesRelativeDateFormatting = false
            f.timeStyle = .short
            f.dateStyle = .none
            return f.string(from: date)
        } else {
            let r = RelativeDateTimeFormatter()
            r.unitsStyle = .short
            return r.localizedString(for: date, relativeTo: Date())
        }
    }
}

// MARK: - Avatar (single)

struct AvatarView: View {
    let user: User
    let size: CGFloat

    var body: some View {
        ZStack {
            if let url = user.avatarUrl {
                FSImage(url: URL(string: url))
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color(.separator), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Circle()
            .fill(Color(.secondarySystemBackground))
            .overlay(
                Text("\(user.firstName) \(user.lastName)")
                    .font(.system(size: max(14, size * 0.38), weight: .semibold))
                    .foregroundStyle(.secondary)
            )
    }
}

struct GroupAvatarView: View {
    let primary: User?
    let secondary: User?
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let primary {
                AvatarView(user: primary, size: size)
            } else {
                Circle().fill(Color(.secondarySystemBackground))
                    .frame(width: size, height: size)
            }

            if let secondary {
                // dijagonalno prema dole-desno; malo manjeg mjerila
                let small = size * 0.72
                AvatarView(user: secondary, size: small)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: max(2, size * 0.05)) // prsten da se vizuelno odvoji
                    )
                    .offset(x: size * 0.36, y: size * 0.36)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .clipped()
    }
}
