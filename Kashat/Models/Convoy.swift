import Foundation
import CoreLocation
import FirebaseFirestore

struct Convoy: Identifiable, Codable {
    let id: String
    var name: String
    var creatorId: String
    var memberIds: [String]
    var isActive: Bool = true
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let creatorId = dictionary["creatorId"] as? String else { return nil }
        self.id = id
        self.name = name
        self.creatorId = creatorId
        self.memberIds = dictionary["memberIds"] as? [String] ?? []
        self.isActive = dictionary["isActive"] as? Bool ?? true
    }
}

struct ConvoyMember: Identifiable, Codable {
    let id: String // User ID
    var name: String
    var lastLocation: CLLocationCoordinate2D?
    var lastActive: Date
    var isSelf: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, name, lastActive
        case latitude, longitude
    }
    
    init(id: String, name: String, lastLocation: CLLocationCoordinate2D? = nil, lastActive: Date = Date(), isSelf: Bool = false) {
        self.id = id
        self.name = name
        self.lastLocation = lastLocation
        self.lastActive = lastActive
        self.isSelf = isSelf
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String else { return nil }
        self.id = id
        self.name = name
        if let lat = (dictionary["latitude"] as? NSNumber)?.doubleValue,
           let lon = (dictionary["longitude"] as? NSNumber)?.doubleValue {
            self.lastLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        self.lastActive = (dictionary["lastActive"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        lastActive = try container.decode(Date.self, forKey: .lastActive)
        if let lat = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let lon = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            lastLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            lastLocation = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(lastActive, forKey: .lastActive)
        if let loc = lastLocation {
            try container.encode(loc.latitude, forKey: .latitude)
            try container.encode(loc.longitude, forKey: .longitude)
        }
    }
}

enum PingType: String, Codable {
    case stuck = "stuck"
    case coffee = "coffee"
    case general = "general"
    case alert = "alert"
    case audio = "audio" // NEW: Walkie Talkie
}

struct ConvoyPing: Identifiable, Codable {
    let id: String
    let memberId: String
    let memberName: String
    let type: PingType
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let audioURL: String? // NEW
    let audioDuration: Double? // NEW
    let transcribedText: String? // NEW: AI Transcription
    
    init(id: String, memberId: String, memberName: String, type: PingType, timestamp: Date, latitude: Double, longitude: Double, audioURL: String? = nil, audioDuration: Double? = nil, transcribedText: String? = nil) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.type = type
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.audioURL = audioURL
        self.audioDuration = audioDuration
        self.transcribedText = transcribedText
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let memberId = dictionary["memberId"] as? String,
              let memberName = dictionary["memberName"] as? String,
              let typeString = dictionary["type"] as? String,
              let type = PingType(rawValue: typeString),
              let lat = (dictionary["latitude"] as? NSNumber)?.doubleValue,
              let lon = (dictionary["longitude"] as? NSNumber)?.doubleValue else { return nil }
        
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.type = type
        self.latitude = lat
        self.longitude = lon
        self.timestamp = (dictionary["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.audioURL = dictionary["audioURL"] as? String
        self.audioDuration = dictionary["audioDuration"] as? Double
        self.transcribedText = dictionary["transcribedText"] as? String
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
