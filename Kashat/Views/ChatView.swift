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
    
    // Get current user ID to check who sent the message
    private var currentUserId: String {
        FirebaseManager.shared.user?.uid ?? ""
    }
    
    // We find the live binding to update the view when messages are added
    // For demo purposes, we use the activeThreadMessages from store for live updates
    var messages: [ChatMessage] {
        // If we have live messages for this thread, use them, otherwise fallback to chat.messages
        return store.activeThreadMessages.isEmpty ? chat.messages : store.activeThreadMessages
    }
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, currentUserId: currentUserId)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        // Scroll to bottom on new message
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Bar
                HStack(spacing: 10) {
                    TextField("اكتب رسالة...", text: $newMessageText)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(Color.white)
                        // Force LTR for typing if needed, or keep natural
                    
                    Button(action: {
                        if !newMessageText.isEmpty {
                            // Send using the other user's ID found in the chat thread
                            store.sendMessage(otherUserId: chat.otherUserId, text: newMessageText)
                            newMessageText = ""
                        }
                    }) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.blue)
                            .symbolEffect(.bounce, value: newMessageText.isEmpty)
                    }
                    .disabled(newMessageText.isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle(chat.otherUserName)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            // Initialize the listener for this specific chat
            store.openChat(with: chat.otherUserId)
        }
    }
}

// MARK: - Components

struct InboxRow: View {
    let chat: ChatThread
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: chat.otherUserImage)
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.otherUserName)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Text(chat.timeString)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                
                Text(chat.lastMessageText)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding()
        .glassEffect(GlassStyle.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let currentUserId: String
    
    var isFromCurrentUser: Bool {
        return message.senderId == currentUserId
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isFromCurrentUser ? Color.blue : Color.white.opacity(0.2))
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .foregroundStyle(Color.white)
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}
