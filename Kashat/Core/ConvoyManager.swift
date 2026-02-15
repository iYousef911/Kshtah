import FirebaseFirestore
import CoreLocation
internal import Combine

class ConvoyManager: ObservableObject {
    @Published var members: [ConvoyMember] = []
    @Published var pings: [ConvoyPing] = []
    @Published var activeConvoy: Convoy?
    
    private let db = Firestore.firestore()
    private var convoyListener: ListenerRegistration?
    private var pingListener: ListenerRegistration?
    
    func joinConvoy(id: String, userId: String, userName: String) {
        // 1. Ensure user is registered as a member in this convoy
        let memberData: [String: Any] = [
            "id": userId,
            "name": userName,
            "lastActive": FieldValue.serverTimestamp()
        ]
        db.collection("convoys").document(id).collection("members").document(userId).setData(memberData, merge: true)
        
        // 2. Start listening to convoy members
        convoyListener = db.collection("convoys").document(id).collection("members")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Convoy Members Listener Error: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents, let self = self else { return }
                self.members = documents.compactMap { ConvoyMember(dictionary: $0.data()) }
                print("👥 Convoy Members Synced: \(self.members.count)")
            }
        
        // 3. Start listening to pings
        pingListener = db.collection("convoys").document(id).collection("pings")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Convoy Pings Listener Error: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents, let self = self else { return }
                let newPings = documents.compactMap { ConvoyPing(dictionary: $0.data()) }
                if let latest = newPings.first, !self.pings.contains(where: { $0.id == latest.id }) {
                    // New ping received! Use notification center to tell the view
                    NotificationCenter.default.post(name: NSNotification.Name("NewConvoyPing"), object: nil)
                }
                self.pings = newPings
                print("🔔 Convoy Pings Synced: \(self.pings.count)")
            }
        
        // 4. Set active convoy metadata
        db.collection("convoys").document(id).getDocument { [weak self] doc, _ in
            if let data = doc?.data(), let self = self {
                self.activeConvoy = Convoy(dictionary: data)
            }
        }
    }
    
    func updateLocation(latitude: Double, longitude: Double, userId: String, convoyId: String) {
        let data: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "lastActive": FieldValue.serverTimestamp()
        ]
        // Use setData with merge: true to ensure it works even if document was somehow missing
        db.collection("convoys").document(convoyId).collection("members").document(userId).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Failed to update location: \(error.localizedDescription)")
            }
        }
    }
    
    func sendPing(type: PingType, memberId: String, memberName: String, lat: Double, lon: Double, convoyId: String, audioURL: String? = nil, duration: Double? = nil, transcribedText: String? = nil) {
        var data: [String: Any] = [
            "id": UUID().uuidString,
            "memberId": memberId,
            "memberName": memberName,
            "type": type.rawValue,
            "timestamp": FieldValue.serverTimestamp(),
            "latitude": lat,
            "longitude": lon
        ]
        
        if let audioURL = audioURL {
            data["audioURL"] = audioURL
        }
        if let duration = duration {
            data["audioDuration"] = duration
        }
        if let transcribedText = transcribedText {
            data["transcribedText"] = transcribedText
        }
        
        db.collection("convoys").document(convoyId).collection("pings").addDocument(data: data) { error in
            if let error = error {
                print("❌ Failed to send ping: \(error.localizedDescription)")
            } else {
                print("✅ Ping sent successfully: \(type.rawValue)")
                
                // NEW: Send Push Notification via OneSignal
                // Get all member IDs except sender
                let recipientIds = self.members.filter { $0.id != memberId }.map { $0.id }
                
                let title = "🚨 نداء قافلة!"
                var message: String
                switch type {
                case .stuck: message = "\(memberName): أنا عالق، أحتاج مساعدة! 🆘"
                case .coffee: message = "\(memberName): وقت القهوة! ☕️"
                case .general: message = "\(memberName): نداء عام 👋"
                case .alert: message = "\(memberName): انتبهوا للطريق! ⚠️"
                case .audio:
                    if let text = transcribedText {
                         message = "\(memberName): \"\(text)\" 🎙️" // AI Powered Notification
                    } else {
                        message = "\(memberName): رسالة صوتية 🎙️"
                    }
                }

                
                NotificationService.shared.sendPushNotification(
                    to: recipientIds,
                    title: title,
                    message: message,
                    data: ["type": "convoy_ping"]
                )
            }
        }
    }
    
    // NEW: Audio Helper
    func sendAudioPing(url: URL, duration: Double, memberId: String, memberName: String, lat: Double, lon: Double, convoyId: String, transcribedText: String? = nil) {
        // 1. Upload Audio
        FirebaseManager.shared.uploadAudio(url: url, folder: "convoy_audio/\(convoyId)") { [weak self] downloadURL in
            guard let downloadURL = downloadURL else { return }
            
            // 2. Send Ping
            self?.sendPing(type: .audio, memberId: memberId, memberName: memberName, lat: lat, lon: lon, convoyId: convoyId, audioURL: downloadURL, duration: duration, transcribedText: transcribedText)
        }
    }
    
    func stopListening() {
        convoyListener?.remove()
        pingListener?.remove()
        activeConvoy = nil
        members = []
        pings = []
    }
}
