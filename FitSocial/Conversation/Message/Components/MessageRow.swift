//
//  MessageRow.swift
//  FitSocial
//
//  Created by Dragan Kos on 28. 8. 2025..
//

import SwiftUI

struct MessageRow: View {
    let messageUi: MessageUi

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
        case "pdf": return "doc.richtext"  // ili "doc.text.fill"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "ppt", "pptx": return "doc.on.clipboard"
        case "zip", "rar": return "archivebox"
        default: return "doc"
        }
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if messageUi.my { Spacer(minLength: 40) }

            VStack(
                alignment: messageUi.my ? .trailing : .leading,
                spacing: 4
            ) {
                if !messageUi.content.isEmpty {
                    Text(messageUi.content)
                        .font(.body)
                        .foregroundStyle(
                            messageUi.my ? .white : .primary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .fill(
                                messageUi.my
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
                                messageUi.my
                                    ? Color.accentColor.opacity(0.6)
                                    : Color(.separator),
                                lineWidth: messageUi.my ? 0 : 0.5
                            )
                        )
                        .accessibilityLabel(messageUi.content)
                } else if messageUi.attachment != nil {
                    switch messageUi.status {
                    case .sending(let progress):
                        VStack(alignment: .leading, spacing: 2) {
                            ProgressView(value: progress)
                            Text("\(Int(progress * 100))%").font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 140)
                    case .sent: ZStack {}

                    case .failed(let error):
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundStyle(.red)
                            Text(error ?? "Greška pri slanju").font(.caption2)
                            Button("Pokušaj ponovo") {
                            }
                            .font(.caption2)
                        }
                    }

                    if let attachment = messageUi.attachment {
                        switch attachment.kind {
                        case .image(let data, _):
                            if let image = data {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 180)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 14)
                                    )
                            }
                        case .video(_, let thumbnail):
                            if let thumb = thumbnail {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 180)
                                    .overlay(alignment: .center) {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 44))
                                            .shadow(radius: 4)
                                    }
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 14)
                                    )
                            } else {
                                ProgressView()
                                    .frame(width: 180, height: 180)
                            }
                        case .document(let uRL):
                            HStack(alignment: .center, spacing: 12) {
                                Image(
                                    systemName: systemIcon(
                                        for: messageUi.attachment?.filename ?? ""
                                    )
                                )
                                .font(.system(size: 28, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .foregroundStyle(
                                    messageUi.my ? .blue : .secondary
                                )

                                Text(messageUi.attachment?.filename ?? "")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .lineLimit(2)
                            }
                        case .remoteImage(_, let url):
                            FSImage(
                                url: url
                            )
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        case .remoteVideo(_, let url, let thumbnailUrl):
                            FSImage(
                                url: thumbnailUrl
                            ).overlay(alignment: .center) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 44))
                                    .shadow(radius: 4)
                            }
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        }
                    }

                }
                Text(timeShort(messageUi.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(messageUi.my ? .trailing : .leading, 6)
            }

            if !messageUi.my { Spacer(minLength: 40) }
        }
        .transition(
            .opacity.combined(
                with: .move(edge: messageUi.my ? .trailing : .leading)
            )
        )
    }
}
