//
//  ChatUserList.swift
//  FitSocial
//
//  Created by Dragan Kos on 30. 8. 2025..
//

import SwiftUI

struct ChatUserListView: View {
    @Bindable private var vm: ChatUserListViewModel

    private let onNext: ([User]) -> Void

    init(vm: ChatUserListViewModel, onNext: @escaping ([User]) -> Void) {
        self.vm = vm
        self.onNext = onNext
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.users) { user in
                    let isSelected = vm.selectedUsers.contains(user)

                    VStack(spacing: 0) {
                        // RED
                        HStack(spacing: 12) {
                            AvatarImage(
                                url: URL(
                                    string: user.avatarUrl(
                                        privateAccess: true
                                    )
                                ),
                                width: 50,
                                height: 50
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }

                            Spacer(minLength: 0)

                            // HIG: trailing accessory za selekciju
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundStyle(.tint)
                                    .transition(
                                        .scale.combined(with: .opacity)
                                    )
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)  // veći vertikalni razmak
                        .background {
                            // HIG: suptilan istaknuti background pri selekciji
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .fill(
                                isSelected
                                    ? Color.accentColor.opacity(0.12)
                                    : .clear
                            )
                        }
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .stroke(
                                isSelected
                                    ? Color.accentColor.opacity(0.35)
                                    : .clear,
                                lineWidth: 1
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.onSelectUser(user: user)
                        }
                        .accessibilityAddTraits(
                            isSelected ? .isSelected : []
                        )
                        .animation(.default, value: isSelected)

                        // Divider uvučen ispod avatara (50) + razmak (12) + lijevi padding (16)
                        Divider()
                            .padding(.leading, 16 + 50 + 12)
                    }
                    .padding(.horizontal, 8)  // “card” razmak lijevo/desno
                    .padding(.vertical, 4)  // razmak između “kartica”
                }

                PagingTrigger(onVisible: {
                    vm.loadMore()
                })
            }
        }
        .onChange(of: vm.searchValue) {
            vm.onSearchChange()
        }
        // HIG: search u naslovnoj traci
        .searchable(
            text: $vm.searchValue,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Pretraga"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Dalje") { onNext(vm.selectedUsers) }
                    .disabled(vm.selectedUsers.isEmpty)  // aktivno tek kad postoji selekcija
            }
        }
    }
}
