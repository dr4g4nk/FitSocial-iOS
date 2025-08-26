//
//  PrifileHeader.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 8. 2025..
//

import SwiftUI

struct ProfileHeader: View {
    private let user: User
    private let imageWidth: CGFloat
    private let imageHeight: CGFloat
    
    init(user: User, imageWidth: CGFloat = 80, imageHeight: CGFloat = 80) {
        self.user = user
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            AvatarImage(url: URL(string: user.avatarUrl!), width: imageWidth, height: imageHeight)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.title2.weight(.semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProfileHeader(user: User(id: 1, firstName: "Marko", lastName: "Markovic", avatarUrl: "https://i.pravatar.cc/150?img=15"))
}


