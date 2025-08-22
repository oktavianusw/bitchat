//
//  ChatsSectionView.swift
//  bitchat
//
//  Created by Saputra on 20/08/25.
//

import SwiftUI

struct ChatsSectionView: View {
    var items: [ChatItem]
    var accent: Color = .orange
    var onTapRow: ((ChatItem) -> Void)? = nil
    
    var body: some View {
        if items.isEmpty {
            ChatsEmptyView(accent: accent)
                .padding(.horizontal, 20)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(title: "Views", textStyle: .largeTitle)
                .padding(.horizontal, 20)

                ListLikeContainer {
                    ForEach(items) { item in
                        Button {
                            onTapRow?(item)
                        } label: {
                            ChatListRowView(item: item, accent: accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens chat \(item.title)")
                    }
                }
            }
        }
    }
}

private struct ListLikeContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 20)
        }
    }
}

#Preview("Chats – Empty") {
    ChatsSectionView(items: [], accent: Color.brandPrimary)
        .background(Color(.systemBackground))
}

#Preview("Chats – With items") {
    let sample: [ChatItem] = [
        ChatItem(title: "Public Channel",
                 time: "19:45", unreadCount: 1, pinned: true,
                 iconSystemName: "megaphone.fill",
                 iconBackground: Color(.systemYellow)),
        ChatItem(title: "Design",
                 time: "18:12", unreadCount: 0, pinned: false,
                 iconSystemName: "paintbrush.fill",
                 iconBackground: Color(.systemTeal))
    ]
    ChatsSectionView(items: sample, accent: Color.brandPrimary)
        .background(Color(.systemBackground))
}
