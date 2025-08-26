//
//  PlayBackCoordinator.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//
import AVFoundation

@MainActor
final class PlaybackCoordinator {
    private let player = AVPlayer()
    private let preloader: VideoPreloader
    private(set) var currentURL: URL?

    init(maxPreloads: Int = 4) {
        preloader = VideoPreloader(maxItems: maxPreloads)
        player.automaticallyWaitsToMinimizeStalling = true
        player.actionAtItemEnd = .pause
        player.isMuted = true
    }

    func prepare(_ url: URL) {
        Task {
            await preloader.enqueue(url)
        }
    }

    func attach(to proxy: VideoPlayerProxy, url: URL) {
        Task{
            if currentURL != url {
                if let item = await preloader.makeItemOnMain(for: url) {
                    player.replaceCurrentItem(with: item)
                } else {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    await preloader.enqueue(url)
                }
                currentURL = url
            }
            proxy.attach(player: player)
        }
    }

    func detach(from proxy: VideoPlayerProxy?) {
        proxy?.detach()
    }

    func play() { player.play() }
    func pause() { player.pause() }

    func setMuted(_ muted: Bool) { player.isMuted = muted }
    var isMuted: Bool { player.isMuted }
}

actor VideoPreloader {
    private let maxAssets: Int
    private var assets: [URL: AVURLAsset] = [:]
    private var order: [URL] = []  // FIFO / LRU red

    init(maxItems: Int) {
        self.maxAssets = maxItems
    }

    /// Dodaj URL za preload. Ako već postoji, ništa ne radi.
    /// Ako ti treba "fire-and-forget", vidi `enqueueDetached(_:)` ispod.
    func enqueue(_ url: URL) async {
        guard assets[url] == nil else { return }

        let asset = AVURLAsset(url: url)

        do {
            // iOS 15+: type-safe key umjesto stringova + bez statusOfValue(forKey:)
            let playable = try await asset.load(.isPlayable)
            guard playable else { return }

            // upiši u cache i održi LRU
            assets[url] = asset
            order.append(url)
            while order.count > maxAssets {
                let old = order.removeFirst()
                assets.removeValue(forKey: old)
            }
        } catch {
            // po želji: log / retry / metrics
            // print("Preload failed for \(url): \(error)")
        }
    }

    /// "Fire-and-forget" enqueue — praktično za pozive iz scroll callback-a.
    func enqueueDetached(_ url: URL) {
        Task { [weak self] in
            // slab self je ok jer actor referenca je class; ako je preload ugašen, Task se tiho gasi
            await self?.enqueue(url)
        }
    }

    /// Vraća **novi** AVPlayerItem za dati URL ako je asset preloaddan.
    /// Kreiranje svježeg item-a iz istog asseta je sigurnije od dijeljenja jednog item-a.
    ///
    /// ⚠️ Swift 6 napomena: ako dobiješ upozorenje o non-sendable rezultatu,
    /// pozovi ovu metodu sa @MainActor konteksta ili koristi `makeItemOnMain(for:)`.
    func makeItem(for url: URL) -> AVPlayerItem? {
        guard let asset = assets[url] else { return nil }
        // "bump" u LRU: tretiraj kao skoro korišteno
        if let i = order.firstIndex(of: url) {
            order.remove(at: i)
            order.append(url)
        }
        return AVPlayerItem(asset: asset)
    }

    /// Varijanta koja pravi item na glavnom threadu (korisno za UI i Swift 6 sendability upozorenja).
    @MainActor
    func makeItemOnMain(for url: URL) async -> AVPlayerItem? {
        await makeItem(for: url)
    }

    /// Ručno izbacivanje jednog URL-a iz cache-a.
    func evict(_ url: URL) {
        assets.removeValue(forKey: url)
        if let i = order.firstIndex(of: url) { order.remove(at: i) }
    }

    /// Pražnjenje cijelog cache-a.
    func clear() {
        assets.removeAll()
        order.removeAll()
    }

    /// Da li je asset već preloaddan.
    func isPreloaded(_ url: URL) -> Bool {
        assets[url] != nil
    }
}
