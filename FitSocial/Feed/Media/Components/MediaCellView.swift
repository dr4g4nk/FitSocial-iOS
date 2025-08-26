import AVKit
//
//  MediaCellView.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//
import SwiftUI

struct MediaCellView: View {
    let media: Media

    let onPlay: (String) -> Void
    let onPause: (String) -> Void
    let onToggleMute: (String, Bool) -> Void

    let onVisibleChange: (String, Double) -> Void
    let onVideoAppear: (String, URL, VideoPlayerProxy) -> Void
    let onVideoDisappear: (String) -> Void

    @State private var proxy = VideoPlayerProxy()
    private var key: String { "\(media.postId)#\(media.id)" }
    private var thumbnail: URL!

    init(
        media: Media,
        onPlay: @escaping (String) -> Void,
        onPause: @escaping (String) -> Void,
        onToggleMute: @escaping (String, Bool) -> Void,
        proxy: VideoPlayerProxy = VideoPlayerProxy(),
        onVisibleChange: @escaping (String, Double) -> Void,
        onVideoAppear: @escaping (String, URL, VideoPlayerProxy) -> Void,
        onVideoDisappear: @escaping (String) -> Void,
        thumbnail: String? = nil
    ) {
        self.media = media
        self.onPlay = onPlay
        self.onPause = onPause
        self.onToggleMute = onToggleMute
        self.proxy = proxy
        self.onVisibleChange = onVisibleChange
        self.onVideoAppear = onVideoAppear
        self.onVideoDisappear = onVideoDisappear

        if let thumbnail {
            self.thumbnail = URL(string: thumbnail)
        } else {
            var components = URLComponents(
                url: media.url!,
                resolvingAgainstBaseURL: false
            )!
            
            components.queryItems =
                (components.queryItems ?? []) + [
                    URLQueryItem(name: "thumbnail", value: "true")
                ]

            self.thumbnail = components.url
        }
    }

    var body: some View {
        if media.isImage {
            FSImage(url: media.url)
                .clipped()
        } else {
            FSVideoPlayer(
                thumbnailUrl: thumbnail,
                proxy: proxy,
                onPlay: { onPlay(key) },
                onPause: { onPause(key) },
                onToggleMute: {bool in  onToggleMute(key, bool) }
            )
            .visibleFraction(id: key) { f in onVisibleChange(key, f) }
            .onAppear { onVideoAppear(key, media.url!, proxy) }
            .onDisappear { onVideoDisappear(key) }
        }
    }
}
