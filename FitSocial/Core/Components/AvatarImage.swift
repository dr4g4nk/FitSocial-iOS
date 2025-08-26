//
//  FeedAsyncImage.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//


import SwiftUI

public struct AvatarImage: View {
    private let url: URL?
    private var width: CGFloat
    private var height: CGFloat
    
    init(url: URL?, width: CGFloat = 40, height: CGFloat = 40) {
        self.url = url
        self.width = width
        self.height = height
    }

    public var body: some View {
        FSImage(url: url)
        .frame(width: width, height: height)
        .clipShape(Circle())
    }

    @ViewBuilder
    private func imageBody(for phase: AsyncImagePhase) -> some View {
        switch phase {
        case .success(let img):
            img.resizable().scaledToFill()
        case .empty:
            ProgressView()
        case .failure:
            Color.gray.opacity(0.2)
        @unknown default:
            Color.gray.opacity(0.2)
        }
    }
}
