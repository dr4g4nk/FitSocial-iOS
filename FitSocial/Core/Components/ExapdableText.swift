//
//  ExapdableText.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftUI

struct ExpandableText: View {
    let text: String
    let lineLimit: Int

    init(_ text: String, lineLimit: Int = 2) {
        self.text = text
        self.lineLimit = lineLimit
    }

    @State private var expanded: Bool = false
    @State private var truncated: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .lineLimit(expanded ? nil : lineLimit)
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        expanded.toggle()
                    }
                }
                .background(
                    Text(text)
                        .lineLimit(lineLimit)
                        .background(
                            GeometryReader { visibleTextGeometry in
                                Color.clear.onAppear {
                                    let size1 = textSize(
                                        text: text,
                                        lineLimit: lineLimit
                                    )
                                    let size2 = textSize(
                                        text: text,
                                        lineLimit: nil
                                    )
                                    truncated = size1 != size2
                                }
                            }
                        )
                        .hidden()
                )

            if truncated {
                Button(action: {
                    withAnimation(.easeInOut) {
                        expanded.toggle()
                    }
                }) {
                    Text(expanded ? "Prikaži manje" : "Prikaži više")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func textSize(text: String, lineLimit: Int?) -> CGSize {
        let label = UILabel()
        label.numberOfLines = lineLimit ?? 0
        label.text = text
        label.lineBreakMode = .byTruncatingTail
        return label.sizeThatFits(
            CGSize(
                width: UIScreen.main.bounds.width - 40,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
    }
}

struct ExpandableText_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableText(
            "Ovo je primjer dužeg teksta koji će biti skraćen na prva dva reda. Kada korisnik klikne na dugme, prikazat će se cijeli tekst.",
            lineLimit: 2
        )
        .padding()
    }
}
