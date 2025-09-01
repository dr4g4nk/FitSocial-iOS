import SwiftUI

private struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroupAvatar(users: chat.users, size: 48)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(chat.subject)
                        .font(.headline) // HIG: istakni primarnu informaciju
                        .lineLimit(1)
                    
                    Spacer(minLength: 8)
                    
                    Text(formattedTime(chat.lastMessageTime))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel(accessibleTime(chat.lastMessageTime))
                }
                
                Text(chat.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2) // HIG: izbjegavaj predugačke redove
            }
        }
        .padding(.vertical, 6)
    }
}