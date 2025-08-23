//
//  ChatRoomView.swift
//  bitchat
//
//  Created by Wentao Guo on 22/08/25.
//

import SwiftUI

// MARK: - Colors

extension Color {
    static let canvasSand = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let outBubble = Color.orange.opacity(0.14)
    static let inBubble = Color.white
    static let inputBG = Color.white

}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    var isMe: Bool
    func path(in rect: CGRect) -> Path {
        var r = rect
        let tail: CGFloat = 6
        var path = Path()

        if isMe {
            r.size.width -= tail
            path.addRoundedRect(in: r, cornerSize: .init(width: 12, height: 12))

            path.move(to: CGPoint(x: r.maxX, y: r.minY + 10))
            path.addQuadCurve(
                to: CGPoint(x: r.maxX + tail, y: r.minY + 14),
                control: CGPoint(x: r.maxX + tail / 2, y: r.minY + 6))
            path.addLine(to: CGPoint(x: r.maxX, y: r.minY + 18))
            path.closeSubpath()
        } else {
            r.origin.x += tail
            r.size.width -= tail
            path.addRoundedRect(in: r, cornerSize: .init(width: 12, height: 12))

            path.move(to: CGPoint(x: r.minX, y: r.minY + 10))
            path.addQuadCurve(
                to: CGPoint(x: r.minX - tail, y: r.minY + 14),
                control: CGPoint(x: r.minX - tail / 2, y: r.minY + 6))
            path.addLine(to: CGPoint(x: r.minX, y: r.minY + 18))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Chat Row

struct ChatRow1: View {
    let msg: ChatMessage
    private let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: msg.isMe ? .trailing : .leading, spacing: 4) {

            HStack(alignment: msg.isMe ? .bottom : .bottom) {
                Text(msg.text)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                if msg.isMe {
                    HStack(spacing: 3) {
                        Text(timeFmt.string(from: msg.time))
                        if msg.delivered {
                            Image(systemName: "checkmark")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.trailing, 6)
                    .padding(.vertical, 2)

                    .offset(x: -6, y: -6)
                }
            }

            if !msg.isMe {
                Text(timeFmt.string(from: msg.time))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
        }
        .background(
            ChatBubbleShape(isMe: msg.isMe)
                .fill(msg.isMe ? Color.outBubble : Color.inBubble)
        )
        .frame(maxWidth: .infinity, alignment: msg.isMe ? .trailing : .leading)
        .padding(.horizontal, 12)
    }
}

// MARK: - Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    var send: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("", text: $text, prompt: Text(" "))
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.inputBG)
                )

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .rotationEffect(.degrees(45))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                            ? .gray.opacity(0.6)
                            : .brandPrimary
                    )
                    .padding(10)
            }
            .disabled(
                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.0001))
        )
        .padding(.horizontal, 8)
    }
}

// MARK: - Header Bar

struct ChatHeader: View {
    let chat: Chat
    let nearbyProfiles: [NearbyProfile]
    var back: () -> Void
    var onGroupUpdated: ((Chat) -> Void)?
    
    
    var body: some View {
        ZStack {
            Color.brandPrimary.ignoresSafeArea(edges: .top)
            
            HStack {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                if chat.type == .privateDM {
                    VStack(alignment: .leading) {
                        Text(chat.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, 6)
                        Text(statusText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.leading, 6)
                    }
                    Spacer()
                } else if chat.type == .group {
                    VStack(alignment: .leading) {
                        Text(chat.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, 6)
                    }
                    Spacer()
                    
                    NavigationLink(destination: EditGroupView(
                        chat: chat,
                        nearbyProfiles: nearbyProfiles,
                        onSave: { updatedDraft in
                            // Create updated chat with new data
                            var updatedChat = chat
                            updatedChat.title = updatedDraft.name
                            updatedChat.about = updatedDraft.about
                            updatedChat.color = updatedDraft.color
                            updatedChat.members = updatedDraft.selectedMembers
                            onGroupUpdated?(updatedChat)
                        }
                    )) {
                        Image("Call")
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text(chat.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, 6)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 56)
    }
    
    private var statusText: String {
        guard chat.type == .privateDM else { return "" }
        
        let presence = chat.members.first?.presence ?? .unknown
        switch presence {
        case .inRange:
            return "Nearby"
        case .outOfRange, .unknown:
            return lastSeenText
        }
    }
    
    private var lastSeenText: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(chat.lastActivity) {
            formatter.dateFormat = "'Last seen at' HH:mm"
        } else if calendar.isDateInYesterday(chat.lastActivity) {
            return "Last seen yesterday"
        } else {
            formatter.dateFormat = "'Last seen on' MM d"
        }
        
        return formatter.string(from: chat.lastActivity)
    }
}

// MARK: - Screen

struct ChatRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatStore: ChatStore
    let initialChat: Chat
    let nearbyProfiles: [NearbyProfile]
    
    @State private var chat: Chat
    @State private var input = ""
    @State private var messages: [ChatMessage]
    
    init(chat: Chat, nearbyProfiles: [NearbyProfile] = []) {
        self.initialChat = chat
        self.nearbyProfiles = nearbyProfiles
        _chat = State(initialValue: chat)
        _messages = State(initialValue: chat.messages)
    }

    var body: some View {
        VStack(spacing: 0) {
            ChatHeader(
                chat: chat,
                nearbyProfiles: nearbyProfiles,
                back: { dismiss() },
                onGroupUpdated: { updatedChat in
                    chat = updatedChat
                    chatStore.updateChat(updatedChat)
                }
            )

            ZStack {
                Color.canvasSand.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { ChatRow1(msg: $0) }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }

                    // 输入条
                    ChatInputBar(text: $input) {
                        let trimmed = input.trimmingCharacters(
                            in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        messages.append(
                            .init(text: trimmed, time: Date(), isMe: true))
                        input = ""
                    }
                    .background(

                        Color.canvasSand
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.06)],
                                    startPoint: .center, endPoint: .bottom)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18, style: .continuous))
                    )
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Preview
//#Preview { NavigationStack { ChatRoomView() } }
