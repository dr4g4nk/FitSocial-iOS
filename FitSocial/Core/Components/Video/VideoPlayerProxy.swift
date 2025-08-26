//
//  VideoPlayerProxy.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//

import AVFoundation
import Combine
import Observation
import SwiftUI

@Observable
public final class VideoPlayerProxy {
    // Reaktivna stanja koja UI direktno koristi
    var isPlaying: Bool = false
    var isMuted: Bool = false
    var readyForDisplay: Bool = false

    // Ne-reaktivno (ne želimo da promjena reference sama po sebi redneruje UI)
    @ObservationIgnored private(set) var player: AVPlayer?
    @ObservationIgnored private var bag = Set<AnyCancellable>()

    func attach(player: AVPlayer?) {
        bag.removeAll()
        self.player = player

        guard let player else {
            isPlaying = false
            readyForDisplay = false
            return
        }

        // AVPlayer -> proxy.isPlaying
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                let playing = (status == .playing)
                if(self?.isPlaying != playing) {
                    self?.isPlaying = playing
                }
            }
            .store(in: &bag)

        // AVPlayer -> proxy.isMuted
        player.publisher(for: \.isMuted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] muted in
                self?.isMuted = muted
            }
            .store(in: &bag)

        // Kraj itema -> isPlaying = false
        if let item = player.currentItem {
            NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.isPlaying = false; self?.player?.seek(to: .zero) }
                .store(in: &bag)
        }
    }

    func detach() {
        bag.removeAll()
        player = nil
        isPlaying = false
        readyForDisplay = false
    }
}
