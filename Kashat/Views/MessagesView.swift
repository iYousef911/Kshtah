import SwiftUI
import FirebaseAuth

struct MessagesView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTab = 1 // Default to Groups (index 1)

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                VStack(spacing: 0) {
                    // Custom Segmented Picker
                    Picker("", selection: $selectedTab) {
                        Text(settings.t("خاص")).tag(0)
                        Text(settings.t("غرف الدردشة")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if selectedTab == 0 {
                        InboxListView()
                    } else {
                        ChatRoomsList()
                    }
                }
            }
            .navigationTitle(settings.t("الرسائل"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if let uid = FirebaseManager.shared.user?.uid {
                    store.fetchUserChats(uid: uid)
                }
                store.fetchChatRooms()
            }
        }
    }
}

// Extract the core list from InboxView to reuse it
struct InboxListView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager

    var activeChats: [ChatThread] {
        store.chats
    }

    var body: some View {
        Group {
            if activeChats.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.white.opacity(0.3))
                    Text(settings.t("لا توجد رسائل بعد"))
                        .font(.headline)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
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
    }
}
