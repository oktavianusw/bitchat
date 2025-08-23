//
//  ChatItem.swift
//  bitchat_iOS
//
//  Created by Saputra on 20/08/25.
//

import SwiftUI

enum Presence: String, Codable {
    case inRange, outOfRange, unknown
}

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

struct Chat: Identifiable, Hashable {
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
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ChatItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String?
    var time: String?
    var unreadCount: Int = 0
    var pinned: Bool = false
    var iconSystemName: String = "megaphone.fill"
    var iconBackground: Color = Color(.systemYellow)
    var presence: Presence?
    
    static func == (lhs: ChatItem, rhs: ChatItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension ChatItem {
    init(chat: Chat) {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        
        self.id = chat.id
        self.title = chat.title

        title = chat.title
        switch chat.type {
        case .group:
            subtitle = chat.lastPreview ?? "Group • \(chat.members.count) members"
            iconSystemName = "" // No icon for groups, just color
            iconBackground = chat.color ?? .gray
            presence = nil
        case .privateDM:
            subtitle = chat.lastPreview ?? "Private"
            iconSystemName = "person.fill"
            iconBackground = .blue
            presence = chat.members.first?.presence ?? .unknown
        case .broadcast:
            subtitle = chat.lastPreview ?? "Public broadcast"
            iconSystemName = "megaphone.fill"
            iconBackground = .yellow
            presence = nil
        }

        time = df.string(from: chat.lastActivity)
        unreadCount = chat.unreadCount
        pinned = chat.pinned
    }
}

