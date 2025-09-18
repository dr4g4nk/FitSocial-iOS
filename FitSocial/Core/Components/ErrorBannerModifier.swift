//
//  ErrorBannerModifier.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import SwiftUI

struct ErrorBannerModifier: ViewModifier {
    @Binding var message: String?
    
    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let msg = message, isVisible {
                banner(msg)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .zIndex(1)
                    .transition(reduceMotion
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        UIAccessibility.post(notification: .announcement,
                                             argument: "Greška: \(msg)")
                    }
            }
        }
        // svaki put kad poruka dobije novu vrijednost -> prikaži i auto-odbij
        .onChange(of: message) { _, newValue in
            guard let newValue, !newValue.isEmpty else {
                hide(animated: true)
                return
            }
            showAndAutoDismiss()
        }
    }
    
    @ViewBuilder
    private func banner(_ text: String) -> some View {
        // Koristi sistemske boje zbog kontrasta i tamne teme
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .imageScale(.medium)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)                // kratka, jasna poruka
                .lineLimit(3)                  // ne preplavljuje ekran
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .foregroundStyle(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red)
                .shadow(radius: 8, y: 4)
        )
        .onTapGesture { hide(animated: true) } // korisnik može odmah odbaciti
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityLabel("Poruka o grešci")
        .accessibilityHint("Dodirnite da sakrijete")
    }
    
    private func showAndAutoDismiss() {
        dismissTask?.cancel()
        withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.9)) {
            isVisible = true
        }
        // Automatsko skrivanje nakon 4s 
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run { hide(animated: true) }
        }
    }
    
    private func hide(animated: Bool) {
        dismissTask?.cancel()
        let action = { isVisible = false }
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } else { action() }
    }
}

public extension View {
    /// Prikaži transient error banner kad se `message` promijeni (nije modalno).
    func errorBanner(message: Binding<String?>) -> some View {
        modifier(ErrorBannerModifier(message: message))
    }
}
