//
//  VideoPlayerView.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//

import AVFoundation
import Combine
import Observation
import SwiftUI

public struct FSVideoPlayer: View {
    public let thumbnailUrl: URL?
    @Bindable private var proxy: VideoPlayerProxy

    // callbacks ka VM-u
    public var onPlay: () -> Void
    public var onPause: () -> Void
    public var onToggleMute: (Bool) -> Void

    @State private var showChrome = true

    public init(
        thumbnailUrl: URL? = nil,
        proxy: VideoPlayerProxy,
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onToggleMute: @escaping (Bool) -> Void
    ) {
        self.thumbnailUrl = thumbnailUrl
        self._proxy = Bindable(wrappedValue: proxy)
        self.onPlay = onPlay
        self.onPause = onPause
        self.onToggleMute = onToggleMute
    }

    public var body: some View {
        ZStack {
            PlayerLayerView(player: proxy.player)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap na video (izvan dugmadi) – toggluje kontrole
                    if proxy.isPlaying {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            showChrome.toggle()
                        }
                    }
                }

            if let thumbnailUrl, !proxy.isPlaying {
                FSImage(url: thumbnailUrl)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .clipped()
            }

            // OVERLAY
            Group {
                if !proxy.isPlaying || showChrome {
                    // Centralni layout: mute iznad, pa play/pause
                    VStack(spacing: 24) {
                        muteButton(style: .small)
                        playPauseButton(style: .large)
                    }
                    .transition(.opacity)
                } else {
                    // Samo mute u donjem desnom dok svira
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            muteButton(style: .small)
                                .padding(12)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .allowsHitTesting(true)
        }
    }

    // MARK: - Buttons

    private enum ButtonStyleKind { case large, small }

    @ViewBuilder
    private func playPauseButton(style: ButtonStyleKind) -> some View {
        Button {
            if proxy.isPlaying {
                onPause()
            } else {
                onPlay()
                withAnimation(.easeInOut(duration: 0.22)) { showChrome = false }
            }
        } label: {
            Image(systemName: proxy.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: style == .large ? 28 : 18, weight: .bold))
                .foregroundStyle(Color(.label))
                .frame(
                    width: style == .large ? 72 : 44,
                    height: style == .large ? 72 : 44
                )
                .background(.background.opacity(0.4))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(proxy.isPlaying ? "Pause video" : "Play video")
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func muteButton(style: ButtonStyleKind) -> some View {
        Button {
            onToggleMute(!proxy.isMuted)
        } label: {
            Image(
                systemName: proxy.isMuted
                    ? "speaker.slash.fill" : "speaker.wave.2.fill"
            )
            .font(.system(size: style == .large ? 24 : 18, weight: .semibold))
            .foregroundStyle(Color(.label))
            .frame(
                width: style == .large ? 72 : 44,
                height: style == .large ? 72 : 44
            )
            .background(.background.opacity(0.4))
            .clipShape(Circle())
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(proxy.isMuted ? "Unmute" : "Mute")
    }
}

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?
    var gravity: AVLayerVideoGravity = .resizeAspectFill
    var onReady: (Bool) -> Void = { _ in }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = gravity
        view.onReady = onReady
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = gravity
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var onReady: ((Bool) -> Void)?

    private var readyObs: NSKeyValueObservation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
        readyObs = playerLayer.observe(
            \.isReadyForDisplay,
            options: [.initial, .new]
        ) { [weak self] _, change in
            guard let self, let ready = change.newValue else { return }
            DispatchQueue.main.async { self.onReady?(ready) }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
