import SwiftUI

private struct GroupAvatar: View {
    let users: [User]
    let size: CGFloat
    
    var body: some View {
        if users.count <= 1 {
            SingleAvatar(name: users.first?.displayName ?? "", url: URL(string: users.first?.avatarUrl ?? ""), size: size)
        } else {
            ZStack {
                SingleAvatar(name: users.first?.displayName ?? "?", url: URL(string: users.first?.avatarUrl ?? ""), size: size * 0.8)
                    .offset(x: size * 0.22, y: size * 0.22)
                    .zIndex(0)
                SingleAvatar(name: users.dropFirst().first?.displayName ?? "?", url: URL(string: users.dropFirst().first?.avatarUrl ?? ""), size: size * 0.8)
                    .zIndex(1)
            }
            .frame(width: size, height: size, alignment: .center)
        }
    }
}