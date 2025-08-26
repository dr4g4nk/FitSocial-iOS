//
//  CommentRow.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftUI


struct CommentRow: View {
    let comment: Comment
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarImage(url: URL(string: comment.user!.avatarUrl!)!)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(comment.user?.firstName ?? "") \(comment.user?.lastName ?? "")").font(.subheadline).bold()
                    Spacer()
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(comment.content).font(.body)
            }
        }
        .padding(.vertical, 6)
    }
}
