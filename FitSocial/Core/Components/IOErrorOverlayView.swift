//
//  IOErrorOverlayView.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import SwiftUI

public struct IOErrorOverlayView: View {
    private let onRetry: () -> Void
    
    public init(onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
    }
    
   public var body: some View {
        VStack(spacing: 12) {
            Text("Došlo je do greške")
                .font(.body)
                .padding(.vertical, 6)
            Button("Pokušaj ponovo") { Task { onRetry() } }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background.opacity(0.8))
    }
}

#Preview {
    IOErrorOverlayView(onRetry: {})
}
