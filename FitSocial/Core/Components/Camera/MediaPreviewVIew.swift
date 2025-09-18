//
//  MediaPreviewVIew.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 9. 2025..
//

import SwiftUI
import AVKit
import AVFoundation
import Photos

struct MediaPreviewView: View {
    let mediaURL: URL
        let isVideo: Bool
        
    @State private var player: AVPlayer?
        
    init(mediaURL: URL, isVideo: Bool) {
        self.mediaURL = mediaURL
        self.isVideo = isVideo
        self.player = isVideo ? AVPlayer(url: mediaURL) : nil
    }
    
        enum SaveStatus {
            case none, saving, success, error
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Group {
                            if isVideo, let player = player {
                                VideoPlayer(player: player)
                                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.8)
                                    .clipped()
                                    .onAppear {
                                        player.play()
                                    }
                            }
                            else {
                                FSImage(url: mediaURL)
                                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.8)
                                    .clipped()
                            }
                        }
                    }
                }
            }
        }
    }

struct MediaPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Primer korišćenja za fotografiju iz bundle-a
        if let imageURL = Bundle.main.url(forResource: "img", withExtension: "jpg") {
            MediaPreviewView(
                mediaURL: imageURL,
                isVideo: false,
            )
            .previewDisplayName("Fotografija Preview")
        }
        
        // Primer korišćenja za video iz bundle-a
        if let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4") {
            MediaPreviewView(
                mediaURL: videoURL,
                isVideo: true,
            )
            .previewDisplayName("Video Preview")
        }
    }
}
