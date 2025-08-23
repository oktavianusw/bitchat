//
//  ChatStore.swift
//  bitchat
//
//  Created by Saputra on 22/08/25.
//

import SwiftUI

final class ChatStore: ObservableObject {
    @Published var chats: [Chat] = []
    
    var chatRows: [ChatItem] {
        chats
            .sorted { $0.lastActivity > $1.lastActivity }
            .map(ChatItem.init(chat:))
    }
    
    func chat(for id: UUID) -> Chat? {
        chats.first(where: { $0.id == id })
    }
    
    func addGroup(from draft: CreateCircleDraft) {
        let now = Date()
        let welcome = ChatMessage(text: "Circle created", time: now, isMe: false)
        let chat = Chat(
            type: .group,
            title: draft.name.isEmpty ? "Untitled Circle" : draft.name,
            color: draft.color,
            about: draft.about,
            members: draft.selectedMembers,
            messages: [welcome]
        )
        chats.insert(chat, at: 0)
    }
    
    @discardableResult
    func addPrivateDM(with other: NearbyProfile) -> Chat {
        let chat = Chat(type: .privateDM, title: other.name, color: nil, about: nil, members: [other], messages: [])
        chats.insert(chat, at: 0)
        return chat
    }
    
    func addBroadcast(title: String, about: String?) {
        let chat = Chat(type: .broadcast, title: title, color: .yellow, about: about, members: [], messages: [])
        chats.insert(chat, at: 0)
    }
    
    func updateChat(_ updatedChat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == updatedChat.id }) {
            chats[index] = updatedChat
        }
    }
}

extension ChatStore {
    static func withSamples() -> ChatStore {
        let store = ChatStore()
        
        func chat(_ title: String, type: ChatType, color: Color? = nil,
                  timeHHmm: String, unread: Int, pinned: Bool,
                  iconBG: Color? = nil) -> Chat {
            let comps = timeHHmm.split(separator: ":").compactMap { Int($0) }
            var date = Date()
            if comps.count == 2 {
                let cal = Calendar.current
                date = cal.date(bySettingHour: comps[0], minute: comps[1], second: 0, of: Date()) ?? Date()
            }
            let last = ChatMessage(text: "Sample preview", time: date, isMe: false)
            
            var members: [NearbyProfile] = []
            switch type {
            case .privateDM:
                members = [.init(name: "Ayu", team: "Team 2", image: nil, initials: "AY", presence: .outOfRange)]
            default: break
            }
            
            var c = Chat(type: type, title: title, color: color ?? iconBG, about: nil,
                         members: members, messages: [last])
            c.unreadCount = unread
            c.pinned = pinned
            return c
        }
        
        var dmChat = chat("Ayu", type: .privateDM,
                          timeHHmm: "20:30", unread: 2, pinned: false)
        dmChat.messages = [
            ChatMessage(text: "Hey, how are you?", time: Date().addingTimeInterval(-3600), isMe: false),
            ChatMessage(text: "I'm fine, thanks!", time: Date().addingTimeInterval(-1800), isMe: true),
            ChatMessage(text: "Are you coming tomorrow?", time: Date().addingTimeInterval(-1200), isMe: false),
            ChatMessage(text: "Yes, see you!", time: Date().addingTimeInterval(-600), isMe: true)
        ]
        
        store.chats = [
            chat("Public Channel", type: .broadcast,
                 color: .yellow, timeHHmm: "19:45", unread: 1, pinned: true),
            chat("Design", type: .group,
                 color: Color(.systemTeal), timeHHmm: "18:12", unread: 0, pinned: false),
            dmChat
        ]
        
        return store
    }
}
