import SwiftUI

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.my { Spacer(minLength: 40) }
            
            VStack(alignment: message.my ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.my ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(message.my ? Color.accentColor : Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(message.my ? Color.accentColor.opacity(0.6) : Color(.separator), lineWidth: message.my ? 0 : 0.5)
                    )
                    .accessibilityLabel(message.text)
                
                Text(timeShort(message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(message.my ? .trailing : .leading, 6)
            }
            
            if !message.my { Spacer(minLength: 40) }
        }
        .transition(.opacity.combined(with: .move(edge: message.my ? .trailing : .leading)))
    }
}