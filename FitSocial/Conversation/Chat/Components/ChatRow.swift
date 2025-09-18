//
//  ChatRow.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import SwiftUI

struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroupAvatar(users: chat.users, size: 48)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(
                        chat.subject
                            ?? chat.users.map({ user in
                                user.displayName
                            }).joined(separator: ", ")
                    )
                    .font(.headline)  // HIG: istakni primarnu informaciju
                    .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(formattedTime(chat.lastMessageTime))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel(
                            accessibleTime(chat.lastMessageTime)
                        )
                }

                Text(chat.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)  // HIG: izbjegavaj predugačke redove
            }
        }
        .padding(.vertical, 6)
    }
}

func accessibleTime(_ date: Date?) -> String {
    guard let date = date else { return "" }
    let f = DateFormatter()
    f.dateStyle = .full
    f.timeStyle = .short
    return f.string(from: date)
}

func formattedTime(_ date: Date?) -> String {
    // Ako je danas, prikaži samo vrijeme; inače kratki datum
    guard let date = date else {
        return ""
    }
    let cal = Calendar.current
    if cal.isDateInToday(date) {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    } else {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }
}

struct GroupAvatar: View {
    let users: [User]
    let size: CGFloat

    var body: some View {
        if users.count <= 1 {
            SingleAvatar(
                name: users.first?.displayName ?? "",
                url: URL(
                    string: users.first?.avatarUrl(privateAccess: true) ?? ""
                ),
                size: size
            )
        } else {
            ZStack {
                SingleAvatar(
                    name: users.first?.displayName ?? "?",
                    url: URL(
                        string: users.first?.avatarUrl(privateAccess: true)
                            ?? ""
                    ),
                    size: size * 0.8
                )
                .zIndex(1)
                SingleAvatar(
                    name: users.dropFirst().first?.displayName ?? "?",
                    url: URL(
                        string: users.dropFirst().first?.avatarUrl(
                            privateAccess: true
                        ) ?? ""
                    ),
                    size: size * 0.8
                )
                .offset(x: size * 0.22, y: size * 0.22)
                .zIndex(0)
            }
            .frame(width: size, height: size, alignment: .center)
        }
    }
}

struct SingleAvatar: View {
    let name: String
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AvatarImage(url: url, width: size, height: size)
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.quaternary, lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    private var initials: some View {
        let letters = initialsFromName(name)
        return Text(letters)
            .font(
                .system(size: size * 0.4, weight: .semibold, design: .rounded)
            )
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
            .foregroundStyle(.primary)
    }

    private var placeholder: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
    }

    private func initialsFromName(_ name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? "?"
        let last = comps.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}
