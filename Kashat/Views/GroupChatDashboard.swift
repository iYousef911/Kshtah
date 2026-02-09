import SwiftUI
import FirebaseAuth

struct GroupChatDashboard: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                LiquidBackgroundView()
                
                ChatRoomsList()
            }
            .navigationTitle(settings.t("غرف الدردشة"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.t("إغلاق")) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                store.fetchChatRooms()
            }
        }
    }
}

struct ChatRoomsList: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(store.chatRooms) { room in
                    NavigationLink(destination: GroupChatView(room: room)) {
                        RoomRow(room: room)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct RoomRow: View {
    let room: ChatRoom
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 55, height: 55)
                Image(systemName: room.type == .spot ? "map.fill" : "person.3.fill")
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(room.timeString)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Text(room.lastMessageText ?? settings.t("لا توجد رسائل بعد"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct GroupChatView: View {
    let room: ChatRoom
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @State private var messageText = ""
    @State private var showGIFPicker = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.activeRoomMessages) { msg in
                                GroupMessageBubble(message: msg, roomId: room.id)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.activeRoomMessages.count) {
                        if let lastId = store.activeRoomMessages.last?.id {
                            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }
                
                // Reply Preview
                if let replyingTo = store.replyingToMessage {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.t("الرد على") + " \(replyingTo.senderName)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text(replyingTo.text)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .padding(.leading, 8)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .overlay(Rectangle().fill(Color.blue).frame(width: 3), alignment: .leading)
                        
                        Button(action: { store.replyingToMessage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Input
                HStack {
                    if store.isBanned {
                        Text(settings.t("لقد تم حظرك من الدردشة"))
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        Button(action: { showGIFPicker = true }) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        TextField(settings.t("اكتب شيئاً..."), text: $messageText)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showGIFPicker) {
            GIFPickerView { gifURL in
                store.sendGroupMessage(roomId: room.id, text: "", gifURL: gifURL)
            }
        }
        .navigationTitle(room.name)
        .onAppear {
            store.openGroupChat(roomId: room.id)
            store.checkBanStatus()
        }
    }
    
    private func sendMessage() {
        store.sendGroupMessage(roomId: room.id, text: messageText)
        messageText = ""
    }
}

struct GroupMessageBubble: View {
    let message: GroupMessage
    let roomId: String // NEW
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager // NEW
    
    var isMine: Bool {
        message.senderId == FirebaseManager.shared.user?.uid
    }
    
    /// Show admin badge for: message has isAdmin, or (my message and current user is admin)
    private var showAdminBadge: Bool {
        if message.isAdmin { return true }
        if isMine, store.userProfile?.isAdmin == true { return true }
        return false
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer() }
            
            if !isMine {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .overlay(Text(message.senderName.prefix(1)).font(.caption2))
            }
            
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                // Show sender name and admin badge for every message
                HStack(spacing: 6) {
                    if isMine {
                        if showAdminBadge {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            Text(settings.t("مدير"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue.opacity(0.95))
                        }
                        Text(message.senderName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        Text(message.senderName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                        if showAdminBadge {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            Text(settings.t("مدير"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue.opacity(0.95))
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                if let replyName = message.replyToSenderName, let replyText = message.replyToText {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text(replyText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 2)
                }
                
                if let gifURL = message.gifURL, let url = URL(string: gifURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isMine ? Color.blue : Color.white.opacity(0.15))
                                .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.5)))
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isMine ? Color.blue : Color.white.opacity(0.15))
                                .overlay(ProgressView().tint(.white))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: 220, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contextMenu {
                        Button { store.replyingToMessage = message } label: {
                            Label(settings.t("رد"), systemImage: "arrowshape.turn.up.left")
                        }
                        if store.userProfile?.isAdmin == true {
                            Button(role: .destructive) {
                                store.deleteMessage(roomId: roomId, messageId: message.id)
                            } label: {
                                Label(settings.t("حذف الرسالة"), systemImage: "trash")
                            }
                            Button(role: .destructive) {
                                store.banUser(userId: message.senderId)
                            } label: {
                                Label(settings.t("حظر المستخدم"), systemImage: "nosign")
                            }
                        }
                    }
                }
                
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMine ? Color.blue : Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                        .contextMenu {
                        Button {
                            store.replyingToMessage = message
                        } label: {
                            Label(settings.t("رد"), systemImage: "arrowshape.turn.up.left")
                        }
                        
                        if store.userProfile?.isAdmin == true {
                            Button(role: .destructive) {
                                store.deleteMessage(roomId: roomId, messageId: message.id)
                            } label: {
                                Label(settings.t("حذف الرسالة"), systemImage: "trash")
                            }
                            
                            Button(role: .destructive) {
                                store.banUser(userId: message.senderId)
                            } label: {
                                Label(settings.t("حظر المستخدم"), systemImage: "nosign")
                            }
                        }
                    }
                }
            }
            
            if !isMine { Spacer() }
        }
    }
}
