//
//  FirebaseManager.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions // Ensure this package is added
import FirebaseRemoteConfig // NEW: Remote Config
import FirebaseAnalytics // NEW: Analytics
import CoreLocation
internal import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    @Published var user: User?
    @Published var verificationId: String?
    
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    lazy var functions = Functions.functions()
    let remoteConfig = RemoteConfig.remoteConfig() // NEW: Remote Config Instance
    
    init() {
        self.user = auth.currentUser
        _ = auth.addStateDidChangeListener { _, user in
            self.user = user
            // Set User ID for Analytics
            if let user = user {
                Analytics.setUserID(user.uid)
            } else {
                Analytics.setUserID(nil)
            }
        }
        setupRemoteConfig() // NEW: Setup on init
    }
    
    // MARK: - Analytics
    func logEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        print("📊 Analytics Event: \(name)")
    }
    
    // MARK: - Remote Config
    func setupRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development; change to 3600 (1 hour) for prod
        remoteConfig.configSettings = settings
        
        // Default values
        let defaults: [String: NSObject] = [
            "is_marketplace_enabled": false as NSObject,
            "is_wallet_enabled": false as NSObject,
            "home_title_text": "وين وجهتك الجاية؟" as NSObject,
            "show_discount_banner": false as NSObject,
            "primary_theme_color": "blue" as NSObject,
            "discount_code": "KASHAT10" as NSObject,
            "is_maintenance_mode": false as NSObject, // NEW: Maintenance
            "support_email": "support@kashat.sa" as NSObject, // NEW: Support
            "min_required_version": "1.0.0" as NSObject, // NEW: Min Version
            
            // NEW: A/B Experiments (Round 2)
            "service_fee_percentage": 0.15 as NSObject, // Experiment 4
            "rent_button_style": "blue_capsule" as NSObject, // Experiment 5
            "default_payment_method": "apple_pay" as NSObject // Experiment 6
        ]
        remoteConfig.setDefaults(defaults)
    }
    
    // Updated to return all config values
    func fetchRemoteConfig(completion: @escaping (Bool, Bool, String, Bool, String, String, Bool, String, String, Double, String, String) -> Void) {
        remoteConfig.fetch { [weak self] status, error in
            if status == .success {
                print("Config fetched!")
                self?.remoteConfig.activate { _, _ in
                    let marketplace = self?.remoteConfig["is_marketplace_enabled"].boolValue ?? false
                    let wallet = self?.remoteConfig["is_wallet_enabled"].boolValue ?? false
                    let homeTitle = self?.remoteConfig["home_title_text"].stringValue ?? "وين وجهتك الجاية؟"
                    let showBanner = self?.remoteConfig["show_discount_banner"].boolValue ?? false
                    let themeColor = self?.remoteConfig["primary_theme_color"].stringValue ?? "blue"
                    let discountCode = self?.remoteConfig["discount_code"].stringValue ?? "KASHAT10"
                    
                    let maintenance = self?.remoteConfig["is_maintenance_mode"].boolValue ?? false
                    let email = self?.remoteConfig["support_email"].stringValue ?? "support@kashat.sa"
                    let minVersion = self?.remoteConfig["min_required_version"].stringValue ?? "1.0.0"
                    
                    // Experiments 4, 5, 6
                    let fee = self?.remoteConfig["service_fee_percentage"].numberValue.doubleValue ?? 0.15
                    let btnStyle = self?.remoteConfig["rent_button_style"].stringValue ?? "blue_capsule"
                    let payMethod = self?.remoteConfig["default_payment_method"].stringValue ?? "apple_pay"
                    
                    DispatchQueue.main.async {
                        completion(marketplace, wallet, homeTitle, showBanner, themeColor, discountCode, maintenance, email, minVersion, fee, btnStyle, payMethod)
                    }
                }
            } else {
                print("Config not fetched")
                DispatchQueue.main.async {
                    // Fallback to defaults
                    let marketplace = self?.remoteConfig["is_marketplace_enabled"].boolValue ?? false
                    let wallet = self?.remoteConfig["is_wallet_enabled"].boolValue ?? false
                    let homeTitle = self?.remoteConfig["home_title_text"].stringValue ?? "وين وجهتك الجاية؟"
                    let showBanner = self?.remoteConfig["show_discount_banner"].boolValue ?? false
                    let themeColor = self?.remoteConfig["primary_theme_color"].stringValue ?? "blue"
                    let discountCode = self?.remoteConfig["discount_code"].stringValue ?? "KASHAT10"
                    
                    let maintenance = self?.remoteConfig["is_maintenance_mode"].boolValue ?? false
                    let email = self?.remoteConfig["support_email"].stringValue ?? "support@kashat.sa"
                    let minVersion = self?.remoteConfig["min_required_version"].stringValue ?? "1.0.0"
                    
                    let fee = self?.remoteConfig["service_fee_percentage"].numberValue.doubleValue ?? 0.15
                    let btnStyle = self?.remoteConfig["rent_button_style"].stringValue ?? "blue_capsule"
                    let payMethod = self?.remoteConfig["default_payment_method"].stringValue ?? "apple_pay"
                    
                    completion(marketplace, wallet, homeTitle, showBanner, themeColor, discountCode, maintenance, email, minVersion, fee, btnStyle, payMethod)
                }
            }
        }
    }
    
    // MARK: - Auth
    func startPhoneAuth(phoneNumber: String, completion: @escaping (Error?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error { completion(error); return }
            DispatchQueue.main.async { self.verificationId = verificationID }
            completion(nil)
        }
    }
    
    func verifyCode(code: String, completion: @escaping (Error?) -> Void) {
        guard let verificationId = verificationId else { return }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)
        auth.signIn(with: credential) { result, error in
            if let error = error { completion(error); return }
            completion(nil)
        }
    }
    
    // MARK: - Social Auth
    
    // Apple Sign In
    func signInWithApple(idToken: String, nonce: String, fullName: String? = nil, completion: @escaping (Error?) -> Void) {
        // Using likely custom or specific SDK extension method 'appleCredential'
        // Passing nil for fullName to match expected signature (likely expects PersonNameComponents? or derived from ASAuthorization)
        // If fullName String is available, we use it for our profile creation separately.
        let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: nil)
        
        auth.signIn(with: credential) { result, error in
            if let error = error { completion(error); return }
            if let user = result?.user {
                self.createUserProfile(user: user, name: fullName)
            }
            completion(nil)
        }
    }
    
    // Google Sign In (Placeholder - specific implementation depends on GoogleSignIn package)
    // You must add `import GoogleSignIn` and ensure the package is added to project
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Error?) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        auth.signIn(with: credential) { result, error in
            if let error = error { completion(error); return }
            if let user = result?.user {
                self.createUserProfile(user: user)
            }
            completion(nil)
        }
    }
    
    func signOut() {
        try? auth.signOut()
        self.verificationId = nil
    }
    
    // MARK: - User Profile
    func fetchUserProfile(uid: String, completion: @escaping (UserProfile?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { completion(nil); return }
            var profile = UserProfile(
                id: uid,
                name: data["name"] as? String ?? "مشترك كشتات",
                phoneNumber: data["phoneNumber"] as? String ?? "",
                balance: data["balance"] as? Double ?? 0.0,
                joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
                favoriteSpotIds: data["favoriteSpotIds"] as? [String] ?? [],
                favoriteGearIds: data["favoriteGearIds"] as? [String] ?? [],
                profileImageURL: data["profileImageURL"] as? String
            )
            profile.isAdmin = data["isAdmin"] as? Bool ?? false // NEW
            completion(profile)
        }
    }
    
    func createUserProfile(user: User, name: String? = nil) {
        let docRef = db.collection("users").document(user.uid)
        docRef.getDocument { snapshot, _ in
            if snapshot?.exists == false {
                let initialName = name ?? "مشترك كشتات"
                let data: [String: Any] = [
                    "name": initialName,
                    "phoneNumber": user.phoneNumber ?? "",
                    "balance": 0.0,
                    "joinDate": Timestamp(date: Date()),
                    "favoriteSpotIds": [],
                    "favoriteGearIds": []
                ]
                docRef.setData(data)
            } else if name != nil {
                // Optionally update name if it was just "Kashat User" placeholder?
                // For now, let's only set it on creation to avoid overwriting user edits.
            }
        }
    }
    
    func updateUserProfile(uid: String, name: String, imageURL: String?, completion: @escaping (Bool) -> Void) {
        var data: [String: Any] = ["name": name]
        if let url = imageURL {
            data["profileImageURL"] = url
        }
        db.collection("users").document(uid).updateData(data) { error in
            completion(error == nil)
        }
    }
    
    // MARK: - Wallet (Cloud Functions)
    func updateBalance(uid: String, delta: Double, completion: @escaping (Bool) -> Void) {
        // Call Cloud Function for security
        // Note: You should implement 'updateBalance' in Cloud Functions similar to 'topUpWallet'
        // For MVP without deploying new function, we use direct write, but Cloud Function is better.
        // Using direct write for now as per previous working code logic:
        let userRef = db.collection("users").document(uid)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDoc: DocumentSnapshot
            do {
                try userDoc = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let oldBalance = userDoc.data()?["balance"] as? Double ?? 0.0
            let newBalance = oldBalance + delta
            
            if newBalance >= 0 {
                transaction.updateData(["balance": newBalance], forDocument: userRef)
                return true
            } else {
                return false
            }
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completion(false)
            } else {
                completion(object as? Bool ?? false)
            }
        }
    }
    
    func deductBalance(uid: String, amount: Double, completion: @escaping (Bool) -> Void) {
        updateBalance(uid: uid, delta: -amount, completion: completion)
    }
    
    // Call Cloud Function for Top Up verification
    func callTopUpWallet(paymentId: String, amount: Double, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "paymentId": paymentId,
            "amount": amount
        ]
        
        functions.httpsCallable("topUpWallet").call(data) { result, error in
            if let error = error {
                print("❌ Cloud Function Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let data = result?.data as? [String: Any],
               let success = data["success"] as? Bool,
               success == true {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Sync Favorites
    func updateFavorites(uid: String, spotIds: [String], gearIds: [String]) {
        db.collection("users").document(uid).updateData([
            "favoriteSpotIds": spotIds,
            "favoriteGearIds": gearIds
        ])
    }
    
    // MARK: - Comments
    func addCommentToSpot(spotId: String, comment: Comment) {
        var data: [String: Any] = [
            "id": comment.id.uuidString,
            "text": comment.text,
            "userId": comment.userId,
            "userName": comment.userName,
            "userImage": comment.userImage,
            "timestamp": Timestamp(date: comment.timestamp)
        ]
        if let rating = comment.rating { data["rating"] = rating }
        if let url = comment.imageURL { data["imageURL"] = url }
        if comment.isAdmin { data["isAdmin"] = true } // NEW
        
        let spotRef = db.collection("spots").document(spotId)
        
        // 1. Add Comment
        spotRef.collection("comments").document(comment.id.uuidString).setData(data)
        
        // 2. Update Spot Rating (Simple Transaction-like update)
        if let newRating = comment.rating {
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let spotDoc: DocumentSnapshot
                do {
                    try spotDoc = transaction.getDocument(spotRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                // ... (Keep existing logic)
                guard let oldRating = spotDoc.data()?["rating"] as? Double,
                      let oldCount = spotDoc.data()?["numberOfRatings"] as? Int else {
                    // Initialize if missing
                    transaction.updateData(["rating": Double(newRating), "numberOfRatings": 1], forDocument: spotRef)
                    return nil
                }
                
                let totalScore = (oldRating * Double(oldCount)) + Double(newRating)
                let newCount = oldCount + 1
                let average = totalScore / Double(newCount)
                
                transaction.updateData(["rating": average, "numberOfRatings": newCount], forDocument: spotRef)
                return nil
            }) { _, _ in }
        }
    }
    
    func fetchCommentsForSpot(spotId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("spots").document(spotId).collection("comments").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { completion([]); return }
            
            let comments = docs.compactMap { doc -> Comment? in
                let data = doc.data()
                guard let text = data["text"] as? String,
                      let userId = data["userId"] as? String,
                      let userName = data["userName"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else { return nil }
                
                var comment = Comment(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    userName: userName,
                    text: text,
                    userId: userId,
                    timestamp: timestamp,
                    userImage: data["userImage"] as? String ?? "person.circle",
                    rating: data["rating"] as? Int
                )
                comment.imageURL = data["imageURL"] as? String
                comment.isAdmin = data["isAdmin"] as? Bool ?? false // NEW
                return comment
            }
            completion(comments)
        }
    }
    
    // MARK: - Chat
    func getChatThreadId(otherUserId: String, completion: @escaping (String) -> Void) {
        guard let currentUid = user?.uid else { return }
        let threadId = currentUid < otherUserId ? "\(currentUid)_\(otherUserId)" : "\(otherUserId)_\(currentUid)"
        let docRef = db.collection("chats").document(threadId)
        docRef.getDocument { snapshot, _ in
            if snapshot?.exists == false {
                let data: [String: Any] = [
                    "participants": [currentUid, otherUserId],
                    "lastMessageText": "بدء المحادثة",
                    "lastMessageTime": Timestamp(date: Date())
                ]
                docRef.setData(data)
            }
            completion(threadId)
        }
    }
    
    func sendMessage(threadId: String, text: String) {
        guard let currentUid = user?.uid else { return }
        let msgData: [String: Any] = [
            "id": UUID().uuidString,
            "text": text,
            "senderId": currentUid,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("chats").document(threadId).collection("messages").addDocument(data: msgData)
        db.collection("chats").document(threadId).updateData([
            "lastMessageText": text,
            "lastMessageTime": Timestamp(date: Date())
        ])
    }
    
    func listenToMessages(threadId: String, completion: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        return db.collection("chats").document(threadId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let messages = docs.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    guard let text = data["text"] as? String,
                          let senderId = data["senderId"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else { return nil }
                    return ChatMessage(id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(), text: text, senderId: senderId, timestamp: timestamp)
                }
                completion(messages)
            }
    }
    
    func fetchUserChats(uid: String, completion: @escaping ([ChatThread]) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { completion([]); return }
                let threads = documents.compactMap { doc -> ChatThread? in
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    guard let otherUserId = participants.first(where: { $0 != uid }) else { return nil }
                    
                    let lastText = data["lastMessageText"] as? String ?? ""
                    let lastTime = (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return ChatThread(
                        id: doc.documentID,
                        otherUserName: "مستخدم", // Placeholder
                        otherUserImage: "person.circle.fill",
                        otherUserId: otherUserId,
                        messages: [],
                        lastMessageText: lastText,
                        lastMessageTime: lastTime
                    )
                }
                completion(threads)
            }
    }

    // MARK: - Image Upload
    func uploadImage(data: Data, folder: String, completion: @escaping (String?) -> Void) {
        let path = "\(folder)/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            ref.downloadURL { url, error in
                if error != nil { completion(nil); return }
                completion(url?.absoluteString)
            }
        }
    }

    // MARK: - Spots
    func fetchSpots(completion: @escaping ([CampingSpot]) -> Void) {
        db.collection("spots").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { completion([]); return }
            
            let spots = documents.compactMap { doc -> CampingSpot? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let lat = data["latitude"] as? Double,
                      let long = data["longitude"] as? Double else { return nil }
                
                return CampingSpot(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: name,
                    location: data["location"] as? String ?? "",
                    type: data["type"] as? String ?? "General",
                    rating: data["rating"] as? Double ?? 0.0,
                    numberOfRatings: data["numberOfRatings"] as? Int ?? 0,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long),
                    imageURL: data["imageURL"] as? String
                )
            }
            completion(spots)
        }
    }
    
    func addSpotToFirebase(_ spot: CampingSpot) {
        var data: [String: Any] = [
            "name": spot.name,
            "location": spot.location,
            "type": spot.type,
            "rating": spot.rating,
            "numberOfRatings": spot.numberOfRatings,
            "latitude": spot.coordinate.latitude,
            "longitude": spot.coordinate.longitude
        ]
        if let url = spot.imageURL { data["imageURL"] = url }
        
        db.collection("spots").document(spot.id.uuidString).setData(data)
    }
    
    // MARK: - Gear
    func fetchGear(completion: @escaping ([GearItem]) -> Void) {
        db.collection("gear").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { completion([]); return }
            
            let gearItems = documents.compactMap { doc -> GearItem? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let price = data["pricePerDay"] as? Int,
                      let category = data["category"] as? String else { return nil }
                
                return GearItem(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: name,
                    pricePerDay: price,
                    imageName: data["imageName"] as? String ?? "tent",
                    category: category,
                    ownerName: data["ownerName"] as? String ?? "Kashat User",
                    rating: data["rating"] as? Double ?? 5.0
                )
            }
            completion(gearItems)
        }
    }
    
    func addGearToFirebase(_ item: GearItem) {
        let data: [String: Any] = [
            "name": item.name,
            "pricePerDay": item.pricePerDay,
            "imageName": item.imageName,
            "category": item.category,
            "ownerName": item.ownerName,
            "rating": item.rating
        ]
        db.collection("gear").document(item.id.uuidString).setData(data)
    }
    
    // MARK: - Bookings & Reviews
    func saveBooking(uid: String, booking: Booking) {
        let bookingData: [String: Any] = [
            "id": booking.id.uuidString,
            "itemName": booking.item.name,
            "itemPrice": booking.item.pricePerDay,
            "itemImage": booking.item.imageName,
            "startDate": Timestamp(date: booking.startDate),
            "endDate": Timestamp(date: booking.endDate),
            "totalPrice": booking.totalPrice,
            "status": booking.status.rawValue,
            "isRated": booking.isRated
        ]
        db.collection("users").document(uid).collection("bookings").document(booking.id.uuidString).setData(bookingData)
    }
    
    func fetchBookings(uid: String, completion: @escaping ([Booking]) -> Void) {
        db.collection("users").document(uid).collection("bookings").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { completion([]); return }
            let bookings = docs.compactMap { doc -> Booking? in
                let data = doc.data()
                guard let itemName = data["itemName"] as? String,
                      let start = (data["startDate"] as? Timestamp)?.dateValue(),
                      let end = (data["endDate"] as? Timestamp)?.dateValue() else { return nil }
                
                let gear = GearItem(
                    name: itemName,
                    pricePerDay: data["itemPrice"] as? Int ?? 0,
                    imageName: data["itemImage"] as? String ?? "tent",
                    category: "General",
                    ownerName: "",
                    rating: 0
                )
                return Booking(
                    id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                    item: gear,
                    startDate: start,
                    endDate: end,
                    totalPrice: data["totalPrice"] as? Double ?? 0.0,
                    status: BookingStatus(rawValue: data["status"] as? String ?? "جاري") ?? .active,
                    isRated: data["isRated"] as? Bool ?? false
                )
            }
            completion(bookings)
        }
    }
    
    func submitReview(uid: String, booking: Booking, review: Review) {
        let reviewData: [String: Any] = [
            "id": review.id,
            "gearId": review.gearId,
            "userId": review.userId,
            "userName": review.userName,
            "rating": review.rating,
            "comment": review.comment,
            "date": Timestamp(date: review.date)
        ]
        db.collection("reviews").document(review.id).setData(reviewData)
        db.collection("users").document(uid).collection("bookings").document(booking.id.uuidString).updateData(["isRated": true])
    }
    
    // MARK: - Notifications
    func updateFCMToken(uid: String, token: String) {
        db.collection("users").document(uid).updateData(["fcmToken": token])
    }
    
    // MARK: - Business Logic
    func recordRevenue(amount: Double, source: String) {
        // FIX: Round to 2 decimal places for clean accounting
        let cleanAmount = (amount * 100).rounded() / 100
        
        db.collection("analytics").document("revenue").collection("transactions").addDocument(data: [
            "amount": cleanAmount,
            "source": source,
            "timestamp": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Account Deletion
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else { return }
        let uid = user.uid

        // 1. Delete Firestore Data
        db.collection("users").document(uid).delete { error in
            if let error = error {
                completion(error)
                return
            }

            // 2. Delete Auth Account
            user.delete { error in
                if let error = error {
                    // Requires re-authentication if it's been a while, handling that might be needed in UI.
                    // For now, we pass the error back.
                    completion(error)
                } else {
                    // 3. Clear Local State
                    self.signOut()
                    completion(nil)
                }
            }
        }
    }

    func processRentalTransaction(payerUid: String, ownerName: String, totalAmount: Double, commission: Double, completion: @escaping (Bool) -> Void) {
        deductBalance(uid: payerUid, amount: totalAmount) { success in
            if success {
                self.recordRevenue(amount: commission, source: "Rental Commission")
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Categories (Dynamic)
    func fetchCategories(completion: @escaping ([Category]) -> Void) {
        db.collection("categories").order(by: "sortOrder", descending: false).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { completion([]); return }
            
            let categories = documents.compactMap { doc -> Category? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let type = data["type"] as? String,
                      let icon = data["icon"] as? String else { return nil }
                
                return Category(
                    id: doc.documentID,
                    name: name,
                    type: type,
                    icon: icon,
                    sortOrder: data["sortOrder"] as? Int ?? 0,
                    isActive: data["isActive"] as? Bool ?? true
                )
            }
            completion(categories)
        }
    }
    
    func addCategoryToFirebase(_ category: Category) {
        let data: [String: Any] = [
            "name": category.name,
            "type": category.type,
            "icon": category.icon,
            "sortOrder": category.sortOrder,
            "isActive": category.isActive
        ]
        db.collection("categories").document(category.id).setData(data)
    }
}

