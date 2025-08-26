//
//  ViewExtension.swift
//  FitSocial
//
//  Created by Dragan Kos on 18. 8. 2025..
//

import SwiftUI

struct VisibilityReader: ViewModifier {
    let onChange: (Bool) -> Void
    @State private var lastIsVisible: Bool = false

    // pragovi sa histerezom – ulaz 0.70, izlaz 0.55
    private let enterThreshold: CGFloat = 0.70
    private let exitThreshold: CGFloat  = 0.55

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                // Koristi local coordinateSpace ScrollView-a radi manje promjena
                Color.clear
                    .onAppear { evaluate(geo: geo) }
                    .onChange(of: geo.frame(in: .global)) {
                        // Throttle – ne računaj baš svaku promjenu
                        DispatchQueue.main.async {
                            evaluate(geo: geo)
                        }
                    }
            }
        )
    }

    private func evaluate(geo: GeometryProxy) {
        let screen = UIScreen.main.bounds
        let frame = geo.frame(in: .global)
        let inter = screen.intersection(frame)
        let ratio = inter.height / max(frame.height, 1)

        let shouldBeVisible: Bool
        if lastIsVisible {
            shouldBeVisible = ratio >= exitThreshold
        } else {
            shouldBeVisible = ratio >= enterThreshold
        }

        if shouldBeVisible != lastIsVisible {
            lastIsVisible = shouldBeVisible
            onChange(shouldBeVisible)
        }
    }
}

extension View {
    func onMostlyVisible(_ handler: @escaping (Bool) -> Void) -> some View {
        modifier(VisibilityReader(onChange: handler))
    }
}


struct VisibilityPref: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct VisibleFraction: ViewModifier {
    let id: String
    let onChange: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: VisibilityPref.self,
                        value: [id: fraction(geo)]
                    )
                }
            )
            .onPreferenceChange(VisibilityPref.self) { map in
                if let f = map[id] { onChange(max(0, min(1, f))) }
            }
    }

    private func fraction(_ geo: GeometryProxy) -> CGFloat {
        let frame = geo.frame(in: .global)
        let screen = UIScreen.main.bounds
        let inter = frame.intersection(screen)
        guard !inter.isNull, !inter.isEmpty else { return 0 }
        let vis = inter.width * inter.height
        let tot = max(frame.width * frame.height, 1)
        return CGFloat(vis / tot)
    }
}

extension View {
    func visibleFraction(id: String, onChange: @escaping (CGFloat) -> Void) -> some View {
        modifier(VisibleFraction(id: id, onChange: onChange))
    }
}

