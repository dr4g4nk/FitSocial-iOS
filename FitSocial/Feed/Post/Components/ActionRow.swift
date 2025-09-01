import SwiftUI

public struct ActionRow: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let image = systemImage{
                    Image(systemName: image)
                        .imageScale(.large)
                }
                Text(title)
                    .font(.body)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}