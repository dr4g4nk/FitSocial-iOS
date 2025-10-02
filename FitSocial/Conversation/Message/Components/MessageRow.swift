//
//  MessageRow.swift
//  FitSocial
//
//  Created by Dragan Kos on 28. 8. 2025..
//

import SwiftUI

struct MessageRow: View {
    let message: MessageEntity
    
    @State private var showTime = false
    
    private func timeShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.timeStyle = .short
        f.dateStyle = .short
        return f.string(from: date)
    }

    private func systemIcon(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "ppt", "pptx": return "doc.on.clipboard"
        case "zip", "rar": return "archivebox"
        default: return "doc"
        }
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if message.my {
                Spacer(minLength: 40)
            } else {
                AvatarImage(url: URL(string: message.user?.avatarUrl ?? ""))
            }

            VStack(
                alignment: message.my ? .trailing : .leading,
                spacing: 4
            ) {
                if let content = message.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(
                            message.my ? .white : .primary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .fill(
                                message.my
                                    ? Color.accentColor
                                    : Color(.secondarySystemBackground)
                            )
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .strokeBorder(
                                message.my
                                    ? Color.accentColor.opacity(0.6)
                                    : Color(.separator),
                                lineWidth: message.my ? 0 : 0.5
                            )
                        )
                        .accessibilityLabel(content)
                } else if message.attachment != nil {
                    switch message.status {
                    case "sending":
                        VStack(alignment: .leading, spacing: 2) {
                            ProgressView(value: message.progress)
                            if let progress = message.progress {
                                Text("\(Int(progress * 100))%").font(
                                    .caption2
                                )
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 140)

                    case "failed":
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundStyle(Color(.systemRed))
                            Text(message.error ?? "Greška pri slanju").font(
                                .caption2
                            )
                            Button("Pokušaj ponovo") {
                            }
                            .font(.caption2)
                        }
                    default: ZStack {}
                    }

                    if let attachment = message.attachment {
                        switch attachment.kind {
                        case "image", "remoteImage":
                            if let url = URL(string: attachment.urlString ?? "")
                            {
                                FSImage(
                                    url: url
                                )
                                .frame(width: 180, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        case "video", "remoteVideo":
                            if let url = URL(
                                string: attachment.thumbnailURLString ?? ""
                            ) {
                                FSImage(
                                    url: url
                                ).overlay(alignment: .center) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 44))
                                        .shadow(radius: 4)
                                }
                                .frame(width: 180, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                            } else {
                                ProgressView()
                                    .frame(width: 180, height: 180)
                            }
                        default:
                            HStack(alignment: .center, spacing: 12) {
                                Image(
                                    systemName: systemIcon(
                                        for: attachment.filename
                                    )
                                )
                                .font(.system(size: 28, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .foregroundStyle(
                                    message.my ? .blue : .secondary
                                )

                                Text(message.attachment?.filename ?? "")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .lineLimit(2)
                            }
                        }

                    }

                }
                if showTime {
                    Text(timeShort(message.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(message.my ? .trailing : .leading, 6)
                }
            }
            if !message.my { Spacer(minLength: 40) }

        }.transition(
            .opacity.combined(
                with: .move(edge: message.my ? .trailing : .leading)
            )
        )
        .onTapGesture {
            showTime = true
        }
    }
}
