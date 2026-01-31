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
    
    @Published var favoriteSpotIds: Set<UUID> = []
    @Published var favoriteGearIds: Set<UUID> = []
    
    @Published var chats: [ChatThread] = []
    @Published var activeThreadMessages: [ChatMessage] = []
    @Published var userProfile: UserProfile?
    @Published var categories: [Category] = [] // NEW: Dynamic Categories
    @Published var recommendedSpots: [RecommendedSpot] = [] // NEW: Smart Recommendations
    
    // Feature Flags
    @Published var isMarketplaceEnabled: Bool = false
    @Published var isWalletEnabled: Bool = false // NEW
    @Published var homeTitleText: String = "وين وجهتك الجاية؟" // NEW: A/B Test Prop
    @Published var showDiscountBanner: Bool = false // NEW: Discount A/B
    @Published var primaryThemeColor: String = "blue" // NEW: Color A/B
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
        return primaryThemeColor == "green" ? .green : .blue
    }
    
    // Core Managers
    private let firebase = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var messageListener: ListenerRegistration?
    
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
        firebase.fetchRemoteConfig { [weak self] (marketplace, wallet, homeTitle, showBanner, themeColor, code, maintenance, email, minVersion, fee, btnStyle, payMethod) in
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
        }
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
                self?.chats = threads
            }
        }
    }

    func getChatThreadId(otherUserId: String, completion: @escaping (String) -> Void) {
        firebase.getChatThreadId(otherUserId: otherUserId, completion: completion)
        
    }

    func openChat(with otherUserId: String) {
        self.activeThreadMessages = []
        
        // Fix Ambiguity: Explicit type for threadId
        firebase.getChatThreadId(otherUserId: otherUserId) { [weak self] (threadId: String) in
            guard let self = self else { return }
            
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
        // Fix Ambiguity: Explicit type for threadId
        firebase.getChatThreadId(otherUserId: otherUserId) { [weak self] (threadId: String) in
            self?.firebase.sendMessage(threadId: threadId, text: text)
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
    
    // MARK: - User Data & Wallet
    func loadUserData(uid: String) {
        firebase.fetchUserProfile(uid: uid) { [weak self] (profile: UserProfile?) in
            DispatchQueue.main.async {
                self?.userProfile = profile
                if let profile = profile {
                    self?.favoriteSpotIds = Set(profile.favoriteSpotIds.compactMap { UUID(uuidString: $0) })
                    self?.favoriteGearIds = Set(profile.favoriteGearIds.compactMap { UUID(uuidString: $0) })
                }
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
                // FIXED: Use only real data
                self.spots = fetchedSpots
                self.fetchRecommendations() // NEW: Trigger AI logic
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
        
        if let imageData = imageData {
            firebase.uploadImage(data: imageData, folder: "spots") { [weak self] (url: String?) in
                guard let self = self, let url = url else { return }
                
                let newSpot = CampingSpot(id: UUID(), name: name, location: location, type: type, rating: 0.0, coordinate: finalCoordinate, imageURL: url)
                
                DispatchQueue.main.async {
                    withAnimation { self.spots.insert(newSpot, at: 0) }
                }
                self.firebase.addSpotToFirebase(newSpot)
            }
        } else {
            let newSpot = CampingSpot(id: UUID(), name: name, location: location, type: type, rating: 0.0, coordinate: finalCoordinate, imageURL: imageURL)
            
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
            newComment.isAdmin = self.userProfile?.isAdmin ?? false // NEW
            newComment.isPro = self.userProfile?.isPro ?? SubscriptionManager.shared.isPro // NEW: Pro status
            
            DispatchQueue.main.async {
                if self.comments[spotId] != nil {
                    withAnimation { self.comments[spotId]?.insert(newComment, at: 0) }
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
    
    // MARK: - Favorites Logic
    func toggleFavoriteSpot(_ spot: CampingSpot) {
        if favoriteSpotIds.contains(spot.id) {
            favoriteSpotIds.remove(spot.id)
        } else {
            favoriteSpotIds.insert(spot.id)
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
}
