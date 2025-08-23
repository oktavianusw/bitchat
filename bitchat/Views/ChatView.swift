//
//  ChatView.swift
//  Circle
//
//  Created by Wentao Guo on 14/08/25.
//

import SwiftUI
struct ChatsView: View {
    @EnvironmentObject var chatStore: ChatStore
    @State private var openSeeMoreSheet = false
    @State private var navigationPath = NavigationPath()
    var profiles: [NearbyProfile] = [
        .init(name: "Saputra", team: "Team 1", image: Image("picture1"), initials: "SU"),
        .init(name: "Ayu",     team: "Team 2", image: Image("picture2"), initials: "AY"),
        .init(name: "Putri",   team: "Team 3", image: Image("picture3"), initials: "PT"),
        .init(name: "Fahrel",    team: "Team 5", image: Image("picture1"), initials: "FA"),
        .init(name: "Bam",    team: "Team 4", image: Image("picture2"), initials: "BAM"),
        .init(name: "Wentao",    team: "Team 1", image: Image("picture4"), initials: "WE")
    ]
    
    init() {
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(Color.brandPrimary)
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.gray,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
        ]
        UISegmentedControl.appearance().setTitleTextAttributes(
            normalAttrs, for: .normal)
        
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
        ]
        UISegmentedControl.appearance().setTitleTextAttributes(
            selectedAttrs, for: .selected)
        
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 16) {
                NearYouSectionView(profiles: profiles,
                                   onTapProfile: { profile in
                    let newChat = chatStore.addPrivateDM(with: profile)
                    navigationPath.append(newChat)
                }, onTapSeeMore: { openSeeMoreSheet.toggle() })
            
            ChatsSectionView(items: chatStore.chatRows)
            
                Spacer()
            }
            .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    NewCircleView(nearbyProfiles: profiles,
                                  onFinish: { draft in
                        chatStore.addGroup(from: draft)
                    }
                    )
                } label: {
                    Image("create-circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add")
                .accessibilityHint("Create a new group.")
                .accessibilityAddTraits(.isButton)
            }
            }
            .sheet(isPresented: $openSeeMoreSheet) {
                VStack {
                    SectionHeaderView(title: "Near You")
                    if profiles.isEmpty {
                        NearbyEmptyView()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 16)],
                                  spacing: 16) {
                            ForEach(profiles) { p in
                                NearbyProfileCardView(profile: p, isScanning: false) {
                                    let newChat = chatStore.addPrivateDM(with: p)
                                    navigationPath.append(newChat)
                                    openSeeMoreSheet = false
                                }
                            }
                        }
                                  .padding(.horizontal, 12)
                                  .padding(.vertical, 4)
                                  .accessibilityLabel("Nearby people list, horizontal")
                    }
                    Spacer()
                }
                .padding()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .background(Color.activityView)
            }
            .navigationDestination(for: Chat.self) { chat in
                ChatRoomView(chat: chat, nearbyProfiles: profiles)
            }
            .navigationDestination(for: ChatItem.self) { chatItem in
                if let chat = chatStore.chat(for: chatItem.id) {
                    ChatRoomView(chat: chat, nearbyProfiles: profiles)
                }
            }
        }
    }
}

#Preview {
    return NavigationStack {
        ChatsView()
    }
    .environmentObject(ChatStore.withSamples())
}
