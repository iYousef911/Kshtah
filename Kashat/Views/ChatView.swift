//
//  ChatView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//

import SwiftUI
import FirebaseAuth // FIX: Required for accessing User.uid

// MARK: - Main Inbox View
struct InboxView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    // Filter out chats that are empty or invalid if needed
    var activeChats: [ChatThread] {
        // In a real app, you would fetch the list of threads from Firestore ('/users/{uid}/chats')
        // For this MVP, we are using the 'store.chats' which currently contains Mock Data + potentially live ones if we synced the list.
        // To make this fully live, we'd need a 'fetchMyChats' function in FirebaseManager.
        // For now, let's stick to the Mock Data structure but ensure the Detail View is live.
        store.chats
    }
    var body: some View {
          NavigationStack {
              ZStack {
                  LiquidBackgroundView()
                  
                  if activeChats.isEmpty {
                      VStack(spacing: 15) {
                          Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 60)).foregroundStyle(Color.white.opacity(0.3))
                          Text("لا توجد رسائل بعد").font(.headline).foregroundStyle(Color.white.opacity(0.5))
                      }
                  } else {
                      ScrollView {
                          VStack(spacing: 12) {
                              ForEach(activeChats) { chat in
                                  NavigationLink(destination: ChatDetailView(chat: chat)) {
                                      InboxRow(chat: chat)
                                  }
                                  .buttonStyle(.plain)
                              }
                          }
                          .padding()
                      }
                  }
              }
              .navigationTitle("الرسائل")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .topBarLeading) {
                      Button("إغلاق") { dismiss() }.foregroundStyle(Color.white)
                  }
              }
              .onAppear {
                  if let uid = FirebaseManager.shared.user?.uid {
                      store.fetchUserChats(uid: uid)
                  }
              }
          }
      }
}

// MARK: - Chat Detail View (The Conversation)
struct ChatDetailView: View {
    let chat: ChatThread
    @EnvironmentObject var store: AppDataStore
    @State private var newMessageText = ""
    @FocusState private var isFocused: Bool
    
    private var isBot: Bool { chat.otherUserId == "kashat_guide_bot" }
    
    private var currentUserId: String {
        FirebaseManager.shared.user?.uid ?? ""
    }
    
    var messages: [ChatMessage] {
        return store.activeThreadMessages.isEmpty ? chat.messages : store.activeThreadMessages
    }
    
    // Quick suggestion chips for the bot
    private let suggestions = [
        "🏔️ وين أكشت هذا الأسبوع؟",
        "🌟 أفضل وقت لمشاهدة النجوم؟",
        "🗻️ قائمة تجهيز لجبل الشفا",
        "﴾🔥 وصفة مكحوس البر"
    ]
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Bot Header Banner (only for AI chat)
                if isBot {
                    BotHeaderView()
                }
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, currentUserId: currentUserId, isBot: isBot)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Typing Indicator
                            if store.isBotTyping {
                                TypingIndicatorView()
                                    .id("typing")
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding()
                        .padding(.bottom, 8)
                    }
                    .onChange(of: messages.count) {
                        withAnimation(.spring(duration: 0.4)) {
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: store.isBotTyping) {
                        if store.isBotTyping {
                            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                        }
                    }
                }
                
                // Quick suggestions (bot only, when no typing)
                if isBot && !store.isBotTyping && messages.count <= 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: { newMessageText = suggestion }) {
                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(.capsule)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Input Bar
                HStack(spacing: 10) {
                    TextField(isBot ? "🤖 اسألني عن الكشتات..." : "اكتب رسالة...", text: $newMessageText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 20))
                        .foregroundStyle(Color.white)
                        .focused($isFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: store.isBotTyping ? "ellipsis" : "paperplane.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(store.isBotTyping ? Color.white.opacity(0.4) : Color.blue)
                            .symbolEffect(.bounce, value: newMessageText.isEmpty)
                    }
                    .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isBotTyping)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle(isBot ? "" : chat.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            store.openChat(with: chat.otherUserId)
        }
    }
    
    private func sendMessage() {
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendMessage(otherUserId: chat.otherUserId, text: text)
        newMessageText = ""
    }
}

// MARK: - Bot Header
struct BotHeaderView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("خبير كشتة")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("AI")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                        .clipShape(.capsule)
                }
                
                Text("مساعدك في تخطيط أجمل رحلاتك ⛺️")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var dotOffset: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Bot avatar
            Circle()
                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: "sparkles").font(.caption2).foregroundStyle(.white))
            
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset[i])
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: dotOffset[i]
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 18))
            
            Spacer()
        }
        .onAppear {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        dotOffset[i] = -6
                    }
                }
            }
        }
    }
}

// MARK: - Components

struct InboxRow: View {
    let chat: ChatThread
    
    private var isBot: Bool { chat.otherUserId == "kashat_guide_bot" }
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                if isBot {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Image(systemName: chat.otherUserImage)
                        .font(.title2)
                        .foregroundStyle(Color.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.otherUserName)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                    if isBot {
                        Text("AI")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .clipShape(.capsule)
                    }
                    Spacer()
                    Text(chat.timeString)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                
                HStack {
                    Text(chat.lastMessageText)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let unread = chat.unreadCount, unread > 0 {
                        Text("\(unread)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(.capsule)
                    }
                }
            }
        }
        .padding()
        .glassEffect(GlassStyle.regular.interactive(), in: .rect(cornerRadius: 20))
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let currentUserId: String
    var isBot: Bool = false
    
    var isFromCurrentUser: Bool {
        return message.senderId == currentUserId
    }
    
    var isFromBot: Bool {
        return message.senderId == "kashat_guide_bot"
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser { Spacer(minLength: 60) }
            
            // Bot avatar for AI messages
            if isFromBot {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "sparkles").font(.caption2).foregroundStyle(.white))
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(bubbleBackground)
                    .clipShape(.rect(
                        topLeadingRadius: isFromCurrentUser ? 18 : 4,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: isFromCurrentUser ? 4 : 18,
                        topTrailingRadius: 18
                    ))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)
                
                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
    
    @ViewBuilder private var bubbleBackground: some View {
        if isFromBot {
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.2, blue: 0.7), Color(red: 0.15, green: 0.3, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isFromCurrentUser {
            Color.blue.opacity(0.85)
        } else {
            Color.white.opacity(0.15)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
