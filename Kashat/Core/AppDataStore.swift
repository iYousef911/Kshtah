//
//  File.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import CoreLocation
internal import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class AppDataStore: ObservableObject {
    // MARK: - Published Properties
    @Published var spots: [CampingSpot] = []
    @Published var gear: [GearItem] = []
    @Published var bookings: [Booking] = []
    @Published var comments: [UUID: [Comment]] = [:]
    @Published var moments: [UUID: [SpotMoment]] = [:] // Local spot moments
    @Published var globalMoments: [SpotMoment] = [] // NEW: Social Feed Moments
    
    // NEW: Trip Planning & Gamification
    @Published var checklists: [TripChecklist] = []
    
    // Remote config

    
    @Published var favoriteSpotIds: Set<UUID> = []
    @Published var favoriteGearIds: Set<UUID> = []
    
    @Published var userProfile: UserProfile?
    @Published var chats: [ChatThread] = [] // RESTORED
    @Published var activeThreadMessages: [ChatMessage] = [] // RESTORED
    @Published var isBotTyping: Bool = false // NEW: Typing indicator for AI bot
    @Published var categories: [Category] = [] // NEW: Dynamic Categories
    @Published var recommendedSpots: [RecommendedSpot] = [] // NEW: Smart Recommendations
    
    // Feature Flags
    @Published var isMarketplaceEnabled: Bool = false
    @Published var isWalletEnabled: Bool = false // NEW
    @Published var homeTitleText: String = "وين وجهتك الجاية؟" // NEW: A/B Test Prop
    @Published var showDiscountBanner: Bool = false // NEW: Discount A/B
    @Published var primaryThemeColor: String = "blue" // NEW: Color A/B
    @Published var currentTheme: AppTheme = .foundingDay // NEW: Event Theme
    @Published var discountCode: String = "KASHAT10" // NEW: Dynamic Discount Code
    
    // Production Configs
    @Published var isMaintenanceMode: Bool = false
    @Published var supportEmail: String = "yad3v.dev@gmail.com"
    @Published var minRequiredVersion: String = "1.0.0"
    
    // Experiment 4, 5, 6
    @Published var serviceFeePercentage: Double = 0.15
    @Published var rentButtonStyle: String = "blue_capsule"
    @Published var defaultPaymentMethod: String = "apple_pay"
    
    // Computed Color Property for A/B Test
    var appColor: Color {
        if currentTheme == .foundingDay {
            return currentTheme.primaryColor
        }
        return primaryThemeColor == "green" ? .green : .blue
    }
    
    // Core Managers
    private let firebase = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var messageListener: ListenerRegistration?
    private var roomMessageListener: ListenerRegistration?
    @Published var replyingToMessage: GroupMessage? // NEW: For Chat Replies
    
    @Published var chatRooms: [ChatRoom] = [] // NEW
    @Published var activeRoomMessages: [GroupMessage] = [] // NEW
    @Published var isBanned: Bool = false // NEW
    
    // Derived Unread Count
    var totalUnreadMessages: Int {
        chats.compactMap { $0.unreadCount }.reduce(0, +)
    }
    
    @Published var successfulActionsCount: Int = UserDefaults.standard.integer(forKey: "successfulActionsCount") {
        didSet { UserDefaults.standard.set(successfulActionsCount, forKey: "successfulActionsCount") }
    }
    
    // Initializer
    init() {
        print("AppDataStore Initialized")
        
        // 1. Listen for Auth Changes
        firebase.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.userProfile = nil // Clear profile on auth change
                if let user = user {
                    self?.loadUserData(uid: user.uid)
                } else {
                    // Reset or handle logged out state
                    self?.userProfile = nil
                }
            }
            .store(in: &cancellables)
        
        // 2. Fetch Initial Content (Gear/Spots)
        fetchGear()
        fetchSpots() // NEW: Ensure spots are fetched
        fetchCategories() // NEW: Dynamic Categories
        
        // 3. Fetch Remote Config
        firebase.fetchRemoteConfig { [weak self] (marketplace: Bool, wallet: Bool, homeTitle: String, showBanner: Bool, themeColor: String, code: String, maintenance: Bool, email: String, minVersion: String, fee: Double, btnStyle: String, payMethod: String, isFoundingDay: Bool) in
            DispatchQueue.main.async {
                self?.isMarketplaceEnabled = marketplace
                self?.isWalletEnabled = wallet
                self?.homeTitleText = homeTitle
                self?.showDiscountBanner = showBanner
                self?.primaryThemeColor = themeColor
                self?.discountCode = code
                
                self?.isMaintenanceMode = maintenance
                self?.supportEmail = email
                self?.minRequiredVersion = minVersion
                
                self?.serviceFeePercentage = fee
                self?.rentButtonStyle = btnStyle
                self?.defaultPaymentMethod = payMethod
                
                // Activation of Founding Day Theme via Remote Config
                if isFoundingDay {
                    self?.currentTheme = .foundingDay
                } else {
                    self?.currentTheme = .standard
                }
            }
        }
        
        // 4. Listen for Real-time Subscription Changes
        SubscriptionManager.shared.$isPro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPro in
                print("💎 AppDataStore: Syncing Pro Status -> \(isPro)")
                if self?.userProfile != nil {
                    self?.userProfile?.isPro = isPro
                }
            }
            .store(in: &cancellables)
        
        // 5. Track last-active date for smart nudge
        UserDefaults.standard.set(Date(), forKey: "last_active_date")
    }
    
    // MARK: - Gear Logic
    func fetchGear() {
        // Explicit Type: (fetchedGear: [GearItem])
        firebase.fetchGear { [weak self] (fetchedGear: [GearItem]) in
            DispatchQueue.main.async {
                // FIXED: Use only real data
                self?.gear = fetchedGear
            }
        }
    }
    
    func seedGearData() {
        for item in MockData.gear {
            firebase.addGearToFirebase(item)
        }
        // Reload after seeding
        self.fetchGear()
    }
    
    func addNewGear(name: String, price: Int, category: String, imageData: Data) {
        guard let uid = firebase.user?.uid, let ownerName = userProfile?.name else { return }
        
        firebase.uploadImage(data: imageData, folder: "gear") { [weak self] (url: String?) in
            guard let self = self, let url = url else { return }
            
            let newGear = GearItem(
                id: UUID(),
                name: name,
                pricePerDay: price,
                imageName: url,
                category: category,
                ownerName: ownerName,
                ownerId: uid, // FIXED: Save real owner ID
                rating: 0.0
            )
            
            DispatchQueue.main.async {
                withAnimation { self.gear.insert(newGear, at: 0) }
            }
            self.firebase.addGearToFirebase(newGear)
        }
    }


    
    // MARK: - Chat Logic
    func fetchUserChats(uid: String) {
        // Explicit Type: (threads: [ChatThread])
        firebase.fetchUserChats(uid: uid) { [weak self] (threads: [ChatThread]) in
            DispatchQueue.main.async {
                var allChats = threads
                
                // NEW: Inject "Kashat Guide" Bot
                let botThread = ChatThread(
                    id: "local_kashat_bot_thread",
                    otherUserName: "خبير كشتة 🤖", // The Bot Name
                    otherUserImage: "sparkles", // SF Symbol
                    otherUserId: "kashat_guide_bot",
                    messages: [], // Local only
                    lastMessageText: "مرحباً! أنا هنا لمساعدتك في التخطيط لرحلتك القادمة.",
                    lastMessageTime: Date()
                )
                
                // Ensure bot is always at the top or present
                if !allChats.contains(where: { $0.otherUserId == "kashat_guide_bot" }) {
                    allChats.insert(botThread, at: 0)
                }
                
                self?.chats = allChats
            }
        }
    }

    func getChatThreadId(otherUserId: String, completion: @escaping (String) -> Void) {
        firebase.getChatThreadId(otherUserId: otherUserId, completion: completion)
        
    }

    func openChat(with otherUserId: String) {
        self.activeThreadMessages = []
        
        // NEW: Bot Logic
        if otherUserId == "kashat_guide_bot" {
            // Load initial/fake messages for the bot
            let welcomeMsg = ChatMessage(
                id: UUID(), // FIXED: Use UUID directly
                text: "حياك الله! 👋 أنا خبير كشتة. آمرني، تبي خطة، نصيحة، أو تعرف وين تكشت اليوم؟",
                senderId: "kashat_guide_bot",
                timestamp: Date()
            )
            self.activeThreadMessages = [welcomeMsg]
            return // Stop execution, don't hit Firebase
        }
        
        // Fix Ambiguity: Explicit type for threadId
        firebase.getChatThreadId(otherUserId: otherUserId) { [weak self] (threadId: String) in
            guard let self = self else { return }
            
            // Mark chat as read natively
            if let currentUid = self.firebase.user?.uid {
                self.firebase.markChatAsRead(threadId: threadId, uid: currentUid)
            }
            
            self.messageListener?.remove()
            
            // Fix Ambiguity: Explicit type for messages
            self.messageListener = self.firebase.listenToMessages(threadId: threadId) { (messages: [ChatMessage]) in
                DispatchQueue.main.async {
                    if !messages.isEmpty {
                        self.activeThreadMessages = messages
                        
                        // Local Notification Logic
                        if let lastMsg = messages.last,
                           let currentUid = self.firebase.user?.uid,
                           lastMsg.senderId != currentUid,
                           Date().timeIntervalSince(lastMsg.timestamp) < 2 {
                            self.sendLocalNotification(text: lastMsg.text)
                        }
                    }
                }
            }
        }
    }
    
    func sendMessage(otherUserId: String, text: String) {
        // NEW: Bot Logic
        if otherUserId == "kashat_guide_bot" {
            guard let currentUid = firebase.user?.uid else { return }
            
            // 1. Add User Message Locally
            let userMsg = ChatMessage(
                id: UUID(), // FIXED: Use UUID directly
                text: text,
                senderId: currentUid,
                timestamp: Date()
            )
            withAnimation {
                self.activeThreadMessages.append(userMsg)
            }
            
            // 2. Show typing indicator
            DispatchQueue.main.async { self.isBotTyping = true }
            
            // 3. Call AI
            Task {
                let responseText = await AIService.shared.askGuide(query: text, isPro: self.userProfile?.isPro ?? false)
                
                // 4. Add Bot Response + clear typing
                let botMsg = ChatMessage(
                    id: UUID(),
                    text: responseText,
                    senderId: "kashat_guide_bot",
                    timestamp: Date()
                )
                
                await MainActor.run {
                    self.isBotTyping = false
                    withAnimation { self.activeThreadMessages.append(botMsg) }
                }
            }
            return
        }
        
        // Fix Ambiguity: Explicit type for threadId
        firebase.getChatThreadId(otherUserId: otherUserId) { [weak self] (threadId: String) in
            self?.firebase.sendMessage(threadId: threadId, text: text, otherUserId: otherUserId)
        }
    }
    
    // MARK: - Group Chat
    func fetchChatRooms() {
        firebase.fetchChatRooms { [weak self] rooms in
            DispatchQueue.main.async {
                self?.chatRooms = rooms
            }
        }
    }
    
    func openGroupChat(roomId: String) {
        self.activeRoomMessages = []
        self.roomMessageListener?.remove()
        self.roomMessageListener = firebase.listenToGroupMessages(roomId: roomId) { [weak self] messages in
            DispatchQueue.main.async {
                self?.activeRoomMessages = messages
            }
        }
    }
    
    
    
    func createSpotChatIfNeeded(spotId: String, spotName: String) {
        firebase.createRoomForSpotIfNeeded(spotId: spotId, spotName: spotName)
    }
    
    func getOrCreateSpotRoom(spotId: String, spotName: String, completion: @escaping (ChatRoom?) -> Void) {
        firebase.getOrCreateRoomForSpot(spotId: spotId, spotName: spotName) { [weak self] room in
            DispatchQueue.main.async {
                if let room = room {
                    // Update local chatRooms if not already present
                    if !(self?.chatRooms.contains(where: { $0.id == room.id }) ?? false) {
                        self?.chatRooms.append(room)
                    }
                }
                completion(room)
            }
        }
    }
    
    // MARK: - Admin Tools
    func promoteToAdmin() {
        firebase.becomeAdmin { [weak self] success in
            if success {
                guard let uid = self?.firebase.user?.uid else { return }
                self?.loadUserData(uid: uid)
            }
        }
    }
    
    func deleteMessage(roomId: String, messageId: String) {
        firebase.deleteGroupMessage(roomId: roomId, messageId: messageId) { success in
            // Listeners will handle the UI update
        }
    }
    
    func banUser(userId: String) {
        firebase.banUser(userId: userId) { success in
            // Logic handled
        }
    }
    
    func checkBanStatus() {
        guard let uid = firebase.user?.uid else { return }
        firebase.checkIfBanned(uid: uid) { [weak self] banned in
            DispatchQueue.main.async {
                self?.isBanned = banned
            }
        }
    }
    
    private func sendLocalNotification(text: String) {
        let content = UNMutableNotificationContent()
        content.title = "رسالة جديدة 💬"
        content.body = text
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Smart Notification Scheduling (AI-powered)
    func scheduleSmartNotificationsIfNeeded() {
        let lastActiveDate = UserDefaults.standard.object(forKey: "last_active_date") as? Date
        Task {
            await SmartNotificationEngine.shared.scheduleSmartNotifications(
                userName: userProfile?.name ?? "الكشاتة",
                favoriteCount: favoriteSpotIds.count,
                lastActiveDate: lastActiveDate,
                topSpots: Array(favoriteSpotIds.prefix(3)).compactMap { id in
                    spots.first(where: { $0.id == id })?.name
                },
                unlockedBadges: userProfile?.unlockedBadges ?? []
            )
        }
    }
    
    // MARK: - User Data & Wallet
    func loadUserData(uid: String) {
        fetchUserChats(uid: uid) // NEW: Load chats automatically
        firebase.fetchUserProfile(uid: uid) { [weak self] (profile: UserProfile?) in
            DispatchQueue.main.async {
                self?.userProfile = profile
                if let profile = profile {
                    self?.favoriteSpotIds = Set(profile.favoriteSpotIds.compactMap { UUID(uuidString: $0) })
                    self?.favoriteGearIds = Set(profile.favoriteGearIds.compactMap { UUID(uuidString: $0) })
                }
                // AI-powered smart notification scheduling runs after profile is ready
                self?.scheduleSmartNotificationsIfNeeded()
            }
        }
        firebase.fetchBookings(uid: uid) { [weak self] (bookings: [Booking]) in
            DispatchQueue.main.async {
                self?.bookings = bookings
            }
        }
    }
    
    func updateProfile(name: String, imageData: Data?) {
        guard let uid = firebase.user?.uid else { return }
        
        if let imageData = imageData {
            firebase.uploadImage(data: imageData, folder: "profiles") { [weak self] (url: String?) in
                guard let self = self, let url = url else { return }
                self.firebase.updateUserProfile(uid: uid, name: name, imageURL: url) { success in
                    if success { self.loadUserData(uid: uid) }
                }
            }
        } else {
            firebase.updateUserProfile(uid: uid, name: name, imageURL: nil) { [weak self] success in
                if success { self?.loadUserData(uid: uid) }
            }
        }
    }
    
    func performWalletTransaction(amount: Double, isDeposit: Bool, completion: @escaping (Bool) -> Void) {
        guard let uid = firebase.user?.uid else { completion(false); return }
        let delta = isDeposit ? amount : -amount
        
        firebase.updateBalance(uid: uid, delta: delta) { success in
            if success {
                self.loadUserData(uid: uid)
            }
            completion(success)
        }
    }
    
    // MARK: - Spots Logic
    func fetchSpots() {
        firebase.fetchSpots { [weak self] (fetchedSpots: [CampingSpot]) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.spots = fetchedSpots
                self.fetchRecommendations() // Trigger AI logic
                self.fetchGlobalMoments() // Load Social Feed
            }
        }
    }
    
    func addSpot(name: String, location: String, type: String, coordinate: CLLocationCoordinate2D?, imageURL: String?, imageData: Data?) {
        // Use provided coordinate or fallback to a random one (for testing/legacy support)
        let finalCoordinate: CLLocationCoordinate2D
        if let coordinate = coordinate {
            finalCoordinate = coordinate
        } else {
            let randomLat = 24.7 + Double.random(in: -0.5...0.5)
            let randomLong = 46.6 + Double.random(in: -0.5...0.5)
            finalCoordinate = CLLocationCoordinate2D(latitude: randomLat, longitude: randomLong)
        }
        
        // Capture User Info
        let creatorName = userProfile?.name ?? "Kashat User"
        let creatorContact = userProfile?.phoneNumber ?? ""
        
        if let imageData = imageData {
            firebase.uploadImage(data: imageData, folder: "spots") { [weak self] (url: String?) in
                guard let self = self, let url = url else { return }
                
                let newSpot = CampingSpot(
                    id: UUID(),
                    name: name,
                    location: location,
                    type: type,
                    rating: 0.0,
                    coordinate: finalCoordinate,
                    imageURL: url,
                    addedBy: creatorName,
                    contactInfo: creatorContact
                )
                
                DispatchQueue.main.async {
                    withAnimation { self.spots.insert(newSpot, at: 0) }
                }
                self.firebase.addSpotToFirebase(newSpot)
            }
        } else {
            let newSpot = CampingSpot(
                id: UUID(),
                name: name,
                location: location,
                type: type,
                rating: 0.0,
                coordinate: finalCoordinate,
                imageURL: imageURL,
                addedBy: creatorName,
                contactInfo: creatorContact
            )
            
            withAnimation { spots.insert(newSpot, at: 0) }
            firebase.addSpotToFirebase(newSpot)
        }
    }
    
    // MARK: - Booking Logic
    func addBooking(item: GearItem, startDate: Date, endDate: Date, totalPrice: Double) {
        guard let uid = firebase.user?.uid else { return }
        
        firebase.deductBalance(uid: uid, amount: totalPrice) { success in
            if success {
                let newBooking = Booking(id: UUID(), item: item, startDate: startDate, endDate: endDate, totalPrice: totalPrice, status: .active, isRated: false)
                
                DispatchQueue.main.async {
                    withAnimation { self.bookings.insert(newBooking, at: 0) }
                    self.userProfile?.balance -= totalPrice
                }
                self.firebase.saveBooking(uid: uid, booking: newBooking)
            } else {
                print("Insufficient funds")
            }
        }
    }
    
    func submitReview(booking: Booking, rating: Int, comment: String) {
        guard let uid = firebase.user?.uid, let userName = userProfile?.name else { return }
        
        let newReview = Review(
            id: UUID().uuidString,
            gearId: booking.item.id.uuidString,
            userId: uid,
            userName: userName,
            rating: rating,
            comment: comment,
            date: Date()
        )
        
        firebase.submitReview(uid: uid, booking: booking, review: newReview)
        loadUserData(uid: uid)
    }
    
    // MARK: - Comments Logic
    func loadComments(for spotId: UUID) {
        firebase.fetchCommentsForSpot(spotId: spotId.uuidString) { [weak self] (fetchedComments: [Comment]) in
            DispatchQueue.main.async {
                self?.comments[spotId] = fetchedComments
            }
        }
    }
    
    func addComment(spotId: UUID, text: String, rating: Int, imageData: Data? = nil) {
        guard let uid = firebase.user?.uid, let name = userProfile?.name else { return }
        
        let commentId = UUID()
        let timestamp = Date()
        
        // Helper to save comment
        func save(url: String?) {
            var newComment = Comment(
                id: commentId,
                userName: name,
                text: text,
                userId: uid,
                timestamp: timestamp,
                userImage: "person.crop.circle",
                rating: rating
            )
            newComment.imageURL = url
            newComment.isAdmin = self.userProfile?.isAdmin ?? false
            newComment.isPro = self.userProfile?.isPro ?? SubscriptionManager.shared.isPro
            
            DispatchQueue.main.async {
                if let existing = self.comments[spotId] {
                    self.comments[spotId] = [newComment] + existing
                } else {
                    self.comments[spotId] = [newComment]
                }
            }
            
            firebase.addCommentToSpot(spotId: spotId.uuidString, comment: newComment)
        }
        
        if let data = imageData {
            firebase.uploadImage(data: data, folder: "comments") { url in
                save(url: url)
            }
        } else {
            save(url: nil)
        }
    }
    
    // MARK: - Moments Logic (New)
    func fetchMoments(for spotId: UUID) {
        // Mock fetch or Firebase fetch
    }
    
    func addMoment(spotId: UUID, imageData: Data, caption: String?) {
        guard let uid = firebase.user?.uid, let name = userProfile?.name else { return }
        
        firebase.uploadImage(data: imageData, folder: "moments") { [weak self] url in
            guard let self = self, let url = url else { return }
            
            let newMoment = SpotMoment(
                id: UUID(),
                userId: uid,
                userName: name,
                imageURL: url,
                timestamp: Date(),
                caption: caption
            )
            
            DispatchQueue.main.async {
                if let existing = self.moments[spotId] {
                    self.moments[spotId] = [newMoment] + existing
                } else {
                    self.moments[spotId] = [newMoment]
                }
            }
        }
    }
    
    func fetchGlobalMoments() {
        firebase.fetchGlobalMoments { [weak self] moments in
            DispatchQueue.main.async {
                withAnimation { self?.globalMoments = moments }
            }
        }
    }
    
    func postGlobalMoment(imageData: Data, caption: String?, spotName: String? = nil) {
        guard let uid = firebase.user?.uid, let name = userProfile?.name else { return }
        
        firebase.uploadImage(data: imageData, folder: "kashta_moments") { [weak self] url in
            guard let self = self, let url = url else { return }
            
            let newMoment = SpotMoment(
                id: UUID(),
                userId: uid,
                userName: name,
                userProfileImageURL: self.userProfile?.profileImageURL,
                imageURL: url,
                timestamp: Date(),
                caption: caption,
                likesCount: 0,
                likedByUserIds: [],
                spotName: spotName
            )
            
            DispatchQueue.main.async {
                withAnimation { self.globalMoments.insert(newMoment, at: 0) }
            }
            
            self.firebase.addGlobalMoment(moment: newMoment)
        }
    }
    
    // MARK: - Like / Unlike Moment
    func toggleLikeMoment(_ moment: SpotMoment) {
        guard let uid = firebase.user?.uid else { return }
        guard let idx = globalMoments.firstIndex(where: { $0.id == moment.id }) else { return }
        
        let alreadyLiked = globalMoments[idx].likedByUserIds.contains(uid)
        
        if alreadyLiked {
            globalMoments[idx].likedByUserIds.removeAll { $0 == uid }
            globalMoments[idx].likesCount = max(0, globalMoments[idx].likesCount - 1)
        } else {
            globalMoments[idx].likedByUserIds.append(uid)
            globalMoments[idx].likesCount += 1
        }
        
        // Sync to Firestore
        let updatedMoment = globalMoments[idx]
        firebase.db.collection("kashta_moments").document(moment.id.uuidString).updateData([
            "likesCount": updatedMoment.likesCount,
            "likedByUserIds": updatedMoment.likedByUserIds
        ])
    }


    // MARK: - Favorites Logic
    func toggleFavoriteSpot(_ spot: CampingSpot) {
        let isFavorite = favoriteSpotIds.contains(spot.id)
        if isFavorite {
            favoriteSpotIds.remove(spot.id)
        } else {
            favoriteSpotIds.insert(spot.id)
            triggerBadgeUnlock(for: "explorer", threshold: 1) // First Favorite
            triggerBadgeUnlock(for: "pro_explorer", threshold: 5) // Fifth Favorite
        }
        syncFavorites()
    }
    
    func toggleFavoriteGear(_ item: GearItem) {
        if favoriteGearIds.contains(item.id) {
            favoriteGearIds.remove(item.id)
        } else {
            favoriteGearIds.insert(item.id)
        }
        syncFavorites()
    }
    
    private func syncFavorites() {
        guard let uid = firebase.user?.uid else { return }
        let spots = favoriteSpotIds.map { $0.uuidString }
        let gear = favoriteGearIds.map { $0.uuidString }
        firebase.updateFavorites(uid: uid, spotIds: spots, gearIds: gear)
    }
    
    func isSpotFavorite(_ spot: CampingSpot) -> Bool {
        return favoriteSpotIds.contains(spot.id)
    }
    
    func isGearFavorite(_ item: GearItem) -> Bool {
        return favoriteGearIds.contains(item.id)
    }
    
    // MARK: - Group Chat logic
    func sendGroupMessage(roomId: String, text: String, gifURL: String? = nil) {
        guard let name = userProfile?.name else { return }
        
        firebase.sendGroupMessage(
            roomId: roomId,
            text: text,
            senderName: name,
            senderImage: userProfile?.profileImageURL,
            isAdmin: userProfile?.isAdmin ?? false,
            gifURL: gifURL,
            replyTo: replyingToMessage // Pass the reply metadata
        )
        
    // After sending, clear the reply state
        DispatchQueue.main.async {
            self.replyingToMessage = nil
        }
    }
    
    // MARK: - AI Recommendations
    func fetchRecommendations() {
        Task {
            // Use current user location from LocationManager
            let userLoc = LocationManager.shared.userLocation
            let recs = await RecommendationManager.shared.getWeekendRecommendations(spots: self.spots, userLocation: userLoc)
            
            DispatchQueue.main.async {
                withAnimation {
                    self.recommendedSpots = recs
                }
            }
        }
    }
    
    // MARK: - Dynamic Categories logic
    func fetchCategories() {
        firebase.fetchCategories { [weak self] fetchedCats in
            DispatchQueue.main.async {
                if fetchedCats.isEmpty {
                    // Fallback / Seeding for first run
                    self?.seedDefaultCategories()
                } else {
                    self?.categories = fetchedCats
                }
            }
        }
    }
    
    // Seed initial categories if Firestore is empty
    func seedDefaultCategories() {
        let defaults = [
            Category(id: "all", name: "الكل", type: "الكل", icon: "square.grid.2x2.fill", sortOrder: 0),
            Category(id: "camps", name: "مخيمات", type: "مخيمات", icon: "tent.fill", sortOrder: 1),
            Category(id: "sand", name: "كثبان", type: "كثبان", icon: "wind", sortOrder: 2),
            Category(id: "valley", name: "وادي", type: "وادي", icon: "water.waves", sortOrder: 3),
            Category(id: "mountain", name: "جبل", type: "جبل", icon: "mountain.2.fill", sortOrder: 4),
            Category(id: "beach", name: "شاطئ", type: "شاطئ", icon: "sun.max.fill", sortOrder: 5)
        ]
        
        self.categories = defaults
        
        // Upload to Firebase for persistence
        for cat in defaults {
            firebase.addCategoryToFirebase(cat)
        }
    }
    
    // MARK: - Gamification Logic (Badges)
    func triggerBadgeUnlock(for badgeId: String, threshold: Int) {
        guard var userProfile = userProfile else { return }
        if userProfile.unlockedBadges.contains(badgeId) { return }
        
        let conditionMet: Bool
        switch badgeId {
        case "explorer": conditionMet = favoriteSpotIds.count >= threshold
        case "pro_explorer": conditionMet = favoriteSpotIds.count >= threshold
        default: conditionMet = false
        }
        
        if conditionMet {
            userProfile.unlockedBadges.append(badgeId)
            self.userProfile = userProfile
            // In a full app, synchronize this with Firestore
            
            // AI-powered badge notification
            let ctx = NotificationContext(
                userName: userProfile.name,
                hour: Calendar.current.component(.hour, from: Date()),
                weekday: Calendar.current.component(.weekday, from: Date()),
                favoriteCount: favoriteSpotIds.count,
                topSpot: spots.first(where: { favoriteSpotIds.contains($0.id) })?.name ?? "الكشتة",
                daysSinceLastActive: 0,
                unlockedBadges: userProfile.unlockedBadges,
                now: Date()
            )
            Task {
                await SmartNotificationEngine.shared.sendEventNotification(type: .badgeMilestone, context: ctx)
            }
        }
    }
    
    // MARK: - Checklists Generation (Default Data)
    func loadDefaultChecklists() {
        if checklists.isEmpty {
            checklists = [
                TripChecklist(name: "كشتة شتوية 🥶", items: [
                    ChecklistItem(title: "حطب للتدفئة"),
                    ChecklistItem(title: "بطانيات شتوية"),
                    ChecklistItem(title: "دلة قهوة و ادوات"),
                    ChecklistItem(title: "كشاف قوي")
                ], emoji: "🥶"),
                TripChecklist(name: "تخييم سريع ⛺️", items: [
                    ChecklistItem(title: "خيمة سريعة الفتح"),
                    ChecklistItem(title: "فرشة أرضية"),
                    ChecklistItem(title: "ترمس ماء", isCompleted: true),
                    ChecklistItem(title: "ولاعة وكبريت")
                ], emoji: "⛺️")
            ]
        }
    }
}
