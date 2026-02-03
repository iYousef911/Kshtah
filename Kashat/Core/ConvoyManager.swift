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
        // Start listening to convoy members
        convoyListener = db.collection("convoys").document(id).collection("members")
            .addSnapshotListener { [unowned self] snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.members = documents.compactMap { ConvoyMember(dictionary: $0.data()) }
            }
        
        // Start listening to pings
        pingListener = db.collection("convoys").document(id).collection("pings")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [unowned self] snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.pings = documents.compactMap { ConvoyPing(dictionary: $0.data()) }
            }
        
        // Set active convoy
        db.collection("convoys").document(id).getDocument { [unowned self] doc, _ in
            if let data = doc?.data() {
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
        db.collection("convoys").document(convoyId).collection("members").document(userId).updateData(data)
    }
    
    func sendPing(type: PingType, memberId: String, memberName: String, lat: Double, lon: Double, convoyId: String) {
        let data: [String: Any] = [
            "id": UUID().uuidString,
            "memberId": memberId,
            "memberName": memberName,
            "type": type.rawValue,
            "timestamp": FieldValue.serverTimestamp(),
            "latitude": lat,
            "longitude": lon
        ]
        
        db.collection("convoys").document(convoyId).collection("pings").addDocument(data: data)
    }
    
    func stopListening() {
        convoyListener?.remove()
        pingListener?.remove()
        activeConvoy = nil
        members = []
        pings = []
    }
}
