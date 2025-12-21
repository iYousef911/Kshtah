//
//  Models.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import Foundation
import CoreLocation

// --- Existing Models ---
struct CampingSpot: Identifiable, Hashable {
    let id: UUID
    let name: String
    let location: String
    let type: String
    let rating: Double
    let numberOfRatings: Int // NEW: Rating Count
    let coordinate: CLLocationCoordinate2D
    let imageURL: String?
    
    init(id: UUID = UUID(), name: String, location: String, type: String, rating: Double, numberOfRatings: Int = 0, coordinate: CLLocationCoordinate2D, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.type = type
        self.rating = rating
        self.numberOfRatings = numberOfRatings
        self.coordinate = coordinate
        self.imageURL = imageURL
    }
    
    static func == (lhs: CampingSpot, rhs: CampingSpot) -> Bool { return lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct GearItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let pricePerDay: Int
    let imageName: String
    let category: String
    let ownerName: String
    var ownerId: String? // NEW: For Chat linking
    let rating: Double
    
    init(id: UUID = UUID(), name: String, pricePerDay: Int, imageName: String, category: String, ownerName: String, ownerId: String? = nil, rating: Double) {
        self.id = id
        self.name = name
        self.pricePerDay = pricePerDay
        self.imageName = imageName
        self.category = category
        self.ownerName = ownerName
        self.ownerId = ownerId
        self.rating = rating
    }
}

// --- UPDATED: User Profile Model ---
struct UserProfile: Identifiable, Codable {
    let id: String
    var name: String
    var phoneNumber: String
    var balance: Double
    var joinDate: Date
    var favoriteSpotIds: [String] = []
    var favoriteGearIds: [String] = []
    var profileImageURL: String?
    var isAdmin: Bool = false // NEW: Admin Flag
}

enum BookingStatus: String, Codable {
    case active = "جاري"
    case completed = "مكتمل"
    case cancelled = "ملغي"
}

struct Booking: Identifiable, Hashable, Codable {
    let id: UUID
    let item: GearItem
    let startDate: Date
    let endDate: Date
    let totalPrice: Double
    let status: BookingStatus
    var isRated: Bool = false
    
    init(id: UUID = UUID(), item: GearItem, startDate: Date, endDate: Date, totalPrice: Double, status: BookingStatus, isRated: Bool = false) {
        self.id = id
        self.item = item
        self.startDate = startDate
        self.endDate = endDate
        self.totalPrice = totalPrice
        self.status = status
        self.isRated = isRated
    }
    
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

struct Comment: Identifiable, Hashable, Codable {
    let id: UUID
    let userName: String
    let text: String
    let userId: String
    let timestamp: Date
    let userImage: String
    var rating: Int?
    var imageURL: String?
    var isAdmin: Bool = false // NEW: Admin Comment
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

struct ChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let senderId: String
    let timestamp: Date
    
    func isFromCurrentUser(uid: String) -> Bool {
        return senderId == uid
    }
}

struct ChatThread: Identifiable, Hashable, Codable {
    let id: String
    let otherUserName: String
    let otherUserImage: String
    let otherUserId: String
    var messages: [ChatMessage]
    var lastMessageText: String
    var lastMessageTime: Date
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: lastMessageTime)
    }
}

struct Review: Identifiable, Codable {
    let id: String
    let gearId: String
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let date: Date
}

struct MockData {
    static let spots = [
        CampingSpot(name: "روضة خريم", location: "الرياض", type: "روضة", rating: 4.8, numberOfRatings: 120, coordinate: CLLocationCoordinate2D(latitude: 25.3, longitude: 47.2)),
        CampingSpot(name: "نفود الثويرات", location: "الزلفي", type: "كثبان", rating: 4.9, numberOfRatings: 85, coordinate: CLLocationCoordinate2D(latitude: 26.3, longitude: 44.8)),
        CampingSpot(name: "وادي لجب", location: "جازان", type: "وادي", rating: 4.7, numberOfRatings: 210, coordinate: CLLocationCoordinate2D(latitude: 17.5, longitude: 42.9)),
        CampingSpot(name: "جبل طويق", location: "القدية", type: "جبل", rating: 4.6, numberOfRatings: 95, coordinate: CLLocationCoordinate2D(latitude: 24.8, longitude: 46.2))
    ]
    
    static let gear = [
        GearItem(name: "خيمة البيرق (كبيرة)", pricePerDay: 150, imageName: "tent.2.fill", category: "خيام", ownerName: "أبو سعد", rating: 4.9),
        GearItem(name: "مولد كهرباء هوندا", pricePerDay: 80, imageName: "bolt.car.fill", category: "كهرباء", ownerName: "مخيمات الرياض", rating: 4.5),
        GearItem(name: "عدة طبخ كاملة", pricePerDay: 50, imageName: "frying.pan.fill", category: "طبخ", ownerName: "أم خالد", rating: 4.8),
        GearItem(name: "منقل شوي فاخر", pricePerDay: 35, imageName: "flame.fill", category: "شواء", ownerName: "أبو سعد", rating: 4.2),
        GearItem(name: "إضاءة ليد 500 واط", pricePerDay: 20, imageName: "lightbulb.fill", category: "كهرباء", ownerName: "كهربائي البر", rating: 4.6),
        GearItem(name: "حبل سحب 4x4", pricePerDay: 40, imageName: "car.circle.fill", category: "انقاذ", ownerName: "فريق غوث", rating: 5.0)
    ]
}
