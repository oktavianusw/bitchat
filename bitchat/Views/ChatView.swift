//
//  ChatView.swift
//  Circle
//
//  Created by Wentao Guo on 14/08/25.
//

import SwiftUI
struct ChatsView: View {
    @EnvironmentObject var chatStore: ChatStore

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
        NavigationStack {
            VStack(spacing: 16) {
                NearYouSectionView(profiles: [
                    .init(name: "Saputra", team: "Team 1", image: Image("picture1"), initials: "SU"),
                    .init(name: "Ayu",     team: "Team 2", image: Image("picture2"), initials: "AY"),
                    .init(name: "Putri",   team: "Team 3", image: Image("picture3"), initials: "PT"),
                    .init(name: "Agus",    team: "Team 4", image: Image("picture4"), initials: "AG")
                ],
                onTapProfile: { _ in print("Tapped") })
                
                ChatsSectionView(items: chatStore.chatRows)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        NewCircleView(nearbyProfiles: [
                            .init(name: "Saputra", team: "Team 1", image: Image("picture1"), initials: "SU"),
                            .init(name: "Ayu",     team: "Team 2", image: Image("picture2"), initials: "AY"),
                            .init(name: "Putri",   team: "Team 3", image: Image("picture3"), initials: "PT"),
                            .init(name: "Agus",    team: "Team 4", image: Image("picture4"), initials: "AG")
                        ],
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
        }
    }
}

#Preview {
    return NavigationStack {
        ChatsView()
    }
    .environmentObject(ChatStore.withSamples())
}
