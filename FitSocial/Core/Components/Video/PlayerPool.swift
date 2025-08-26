//
//  PlayerPool.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//
import Observation
import AVKit

@MainActor
@Observable
final class PlayerPool {
    static let shared = PlayerPool()

    private let capacity = 4
    private var players: [AVPlayer] = []
    private var keyToPlayer: [String: AVPlayer] = [:]
    private var playerToKey: [ObjectIdentifier: String] = [:]
    private var endObservers: [String: NSObjectProtocol] = [:]


    init() {
        players = (0..<capacity).map { _ in
            let p = AVPlayer()
            p.automaticallyWaitsToMinimizeStalling = true
            return p
        }
    }

    func player(for key: String, url: URL) -> AVPlayer {
        if let p = keyToPlayer[key] {
            ensureItem(p, url: url)
            return p
        }
        if let free = players.first(where: { playerToKey[ObjectIdentifier($0)] == nil }) {
            bind(player: free, to: key, url: url)
            return free
        }
        // najsimpliji “LRU” – izbaci prvog vezanog
        let victim = keyToPlayer.values.first ?? players[0]
        unbind(victim)
        bind(player: victim, to: key, url: url)
        return victim
    }

    func preload(keys: [String], urlProvider: (String) -> URL?) {
        for k in keys {
            guard let url = urlProvider(k) else { continue }
            let p = player(for: k, url: url)
            p.pause()
            p.currentItem?.preferredForwardBufferDuration = 10
        }
    }

    func pauseAll(except keep: AVPlayer? = nil) {
        for p in players where p !== keep {
            p.pause()
        }
    }

    // MARK: helpers
    private func ensureItem(_ player: AVPlayer, url: URL, key: String? = nil) {
        if let item = player.currentItem,
           let asset = item.asset as? AVURLAsset,
           asset.url == url { return }

        // Makni stari observer za taj ključ (ako postoji)
        if let k = key, let token = endObservers[k] {
            NotificationCenter.default.removeObserver(token)
            endObservers.removeValue(forKey: k)
        }

        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        item.preferredForwardBufferDuration = 10
        player.replaceCurrentItem(with: item)
    }

    private func bind(player: AVPlayer, to key: String, url: URL) {
        ensureItem(player, url: url, key: key)
        keyToPlayer[key] = player
        playerToKey[ObjectIdentifier(player)] = key

        // Registruj observer i zapamti token
        let token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        endObservers[key] = token
    }

    private func unbind(_ player: AVPlayer) {
        if let key = playerToKey[ObjectIdentifier(player)] {
            if let token = endObservers[key] {
                NotificationCenter.default.removeObserver(token)
                endObservers.removeValue(forKey: key)
            }
            keyToPlayer.removeValue(forKey: key)
            playerToKey.removeValue(forKey: ObjectIdentifier(player))
        }
        player.replaceCurrentItem(with: nil)
    }
}
