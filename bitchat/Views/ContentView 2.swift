//
//  ContentView.swift
//  Circle
//
//  Created by Wentao Guo on 14/08/25.
//
import SwiftUI

struct Homepage: View {
    @StateObject private var chatStore = ChatStore()
    
    let nearbyProfiles: [NearbyProfile] = [
        .init(name: "Saputra", team: "Team 1", image: Image("picture1"), initials: "SU"),
        .init(name: "Ayu",     team: "Team 2", image: Image("picture2"), initials: "AY"),
        .init(name: "Putri",   team: "Team 3", image: Image("picture3"), initials: "PT"),
        .init(name: "Fahrel",    team: "Team 5", image: Image("picture1"), initials: "FA"),
        .init(name: "Bam",    team: "Team 4", image: Image("picture2"), initials: "BAM"),
        .init(name: "Wentao",    team: "Team 1", image: Image("picture4"), initials: "WE")
    ]
    
    init(store: ChatStore = ChatStore()) {
        _chatStore = StateObject(wrappedValue: store)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.brandPrimary)

     
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(
            Color.white
        ).withAlphaComponent(0.6)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.white).withAlphaComponent(0.6)
        ]

   
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .white
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes =
            [
                .foregroundColor: UIColor.white
            ]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }

    var body: some View {
        NavigationStack {
            TabView {
                ChatsView()
                    .tabItem {
                        Image("message-question")
                            .renderingMode(.template)
                        Text("Chats")
                    }
                Text("Profile")
                    .tabItem {
                        Image("personalcard")
                            .renderingMode(.template)
                        Text("Profile")
                    }
            }
            .tint(Color.brandPrimary)
            .navigationDestination(for: ChatItem.self) { item in
                if let chat = chatStore.chat(for: item.id) {
                    ChatRoomView(
                        chat: chat,
                        nearbyProfiles: nearbyProfiles
                    )
                    .environmentObject(chatStore)
                } else {
                    Text("Chat not found")
                }
            }
        }
        .environmentObject(chatStore)
    }
}

#Preview {
    Homepage(store: ChatStore.withSamples())
}
