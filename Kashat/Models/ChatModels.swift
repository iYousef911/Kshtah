import Foundation
import FirebaseFirestore

struct ChatRoom: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var lastMessageText: String?
    var lastMessageTime: Date?
    var participantCount: Int
    var type: RoomType
    var spotId: String? // Optional: Link to a specific camping spot
    
    enum RoomType: String, Codable {
        case general
        case region
        case spot
    }
    
    var timeString: String {
        guard let date = lastMessageTime else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct GroupMessage: Identifiable, Codable {
    var id: String
    var text: String
    var senderId: String
    var senderName: String
    var senderImage: String?
    var timestamp: Date
    var isAdmin: Bool = false // Admin badge indicator
    var gifURL: String? // Optional GIF image URL
    
    // Reply Fields
    var replyToId: String?
    var replyToText: String?
    var replyToSenderName: String?
}
