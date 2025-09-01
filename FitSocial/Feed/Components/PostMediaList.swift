//
//  AttachmentsList.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import PhotosUI
import SwiftUI

struct PostMediaList: View {
    let postMedia: [MediaUi]
    var onRemove: (MediaUi) -> Void
    var onMove: (_ from: UUID, _ to: UUID?) -> Void

    var body: some View {
        if postMedia.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 12) {
                ForEach(postMedia) { media in
                    PostMediaCard(media: media, onRemove: { onRemove(media) })
                        .overlay(alignment: .trailing) {
                            Image(systemName: "line.3.horizontal")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .accessibilityHidden(true)
                        }
                        .draggable(media.id.uuidString)  // iOS 17+
                        .dropDestination(for: String.self) { items, _ in
                            guard let first = items.first,
                                let source = UUID(uuidString: first)
                            else { return false }
                            onMove(source, media.id)
                            return true
                        } isTargeted: { _ in
                        }
                }
            }
            // dozvoli drop i na kraj liste (target == nil)
            .dropDestination(for: String.self) { items, _ in
                guard let first = items.first,
                    let source = UUID(uuidString: first)
                else { return false }
                onMove(source, nil)
                return true
            }
        }
    }
}

private struct PostMediaCard: View {
    let media: MediaUi
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.08))

                switch media.kind {
                case .image(let data, _):
                    if let image = data {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 160,
                                maxHeight: 380
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                case .video(_, let thumbnail):
                    if let thumb = thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 160,
                                maxHeight: 380
                            )
                            .overlay(alignment: .center) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 44))
                                    .shadow(radius: 4)
                                    .foregroundStyle(.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        ProgressView()
                            .frame(height: 160)
                    }
                case .remoteImage(_, let url):
                    FSImage(url: url).frame(
                        maxWidth: .infinity,
                        minHeight: 160,
                        maxHeight: 380
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                case .remoteVideo(_, _, let thumbnailURL):
                    FSImage(url: thumbnailURL).frame(
                        maxWidth: .infinity,
                        minHeight: 160,
                        maxHeight: 380
                    )
                    .overlay(alignment: .center) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .shadow(radius: 4)
                            .foregroundStyle(.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .accessibilityLabel(media.accessibilityLabel)

            HStack {
                Text(media.accessibilityLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onRemove()
                } label: {
                    Label("Ukloni", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .imageScale(.medium)
                        .padding(8)
                }
                .tint(.red)
                .accessibilityLabel("Ukloni prilog")
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .clipped()
    }
}
