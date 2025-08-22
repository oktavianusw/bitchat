//
//  ChatItem.swift
//  bitchat_iOS
//
//  Created by Saputra on 20/08/25.
//

import SwiftUI

enum ChatType: String, Codable {
    case group
    case privateDM
    case broadcast
}

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let time: Date
    let isMe: Bool
    var delivered: Bool = true
}

struct Chat: Identifiable {
    let id = UUID()
    var type: ChatType
    var title: String
    var color: Color?
    var about: String?
    var members: [NearbyProfile]
    var messages: [ChatMessage] = []
    var pinned: Bool = false
    var unreadCount: Int = 0
    var lastPreview: String? { messages.last?.text }
    var lastActivity: Date { messages.last?.time ?? Date()}
}

struct ChatItem: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String?
    var time: String?
    var unreadCount: Int = 0
    var pinned: Bool = false
    var iconSystemName: String = "megaphone.fill"
    var iconBackground: Color = Color(.systemYellow)
}

extension ChatItem {
    init(chat: Chat) {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        
        self.title = chat.title
        switch chat.type {
        case .group:
            self.subtitle = chat.lastPreview ?? "Group • \(chat.members.count) members"
            self.iconSystemName = "person.3.fill"
            self.iconBackground = chat.color ?? .gray
        case .privateDM:
            self.subtitle = chat.lastPreview ?? "Private"
            self.iconSystemName = "person.fill"
            self.iconBackground = .blue
        case .broadcast:
            self.subtitle = chat.lastPreview ?? "Public broadcast"
            self.iconSystemName = "megaphone.fill"
            self.iconBackground = .yellow
        }
        
        self.time = df.string(from: chat.lastActivity)
        self.unreadCount = chat.unreadCount
        self.pinned = chat.pinned
    }
}
