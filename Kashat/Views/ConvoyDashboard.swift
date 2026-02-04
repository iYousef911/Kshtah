import SwiftUI
import MapKit

struct ConvoyDashboard: View {
    @StateObject private var manager = ConvoyManager()
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    let spot: CampingSpot?
    
    init(spot: CampingSpot? = nil) {
        self.spot = spot
    }
    
    // Dynamic Convoy ID based on spot or fallback to global
    private var convoyId: String {
        if let spot = spot {
            return "convoy_\(spot.id)"
        }
        return "global_convoy"
    }
    
    var body: some View {
        ZStack {
            // Background Map
            Map {
                ForEach(manager.members) { member in
                    if let loc = member.lastLocation {
                        Annotation(member.name, coordinate: loc) {
                            VStack {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                                Text(member.name)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(settings.t("القافلة النشطة"))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(spot?.name ?? settings.t("القافلة العامة"))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding()
                
                Spacer()
                
                // Pings List
                if let lastPing = manager.pings.first {
                    HStack {
                        Image(systemName: pingIcon(for: lastPing.type))
                            .foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text(lastPing.memberName)
                                .font(.caption.bold())
                            Text(pingText(for: lastPing.type))
                                .font(.caption2)
                        }
                        Spacer()
                    }
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Action Bar (Walkie-Talkie)
                HStack(spacing: 15) {
                    PingButton(icon: "alert.fill", color: .red) {
                        sendPing(.stuck)
                    }
                    PingButton(icon: "cup.and.saucer.fill", color: .orange) {
                        sendPing(.coffee)
                    }
                    PingButton(icon: "hand.wave.fill", color: .green) {
                        sendPing(.general)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(manager.members.count) " + settings.t("متصلين"))
                            .font(.caption2.bold())
                        Text(settings.t("بث حي"))
                            .font(.system(size: 8))
                            .foregroundStyle(.green)
                    }
                    .foregroundStyle(.white)
                }
                .padding()
                .glassEffect(.regular, in: Capsule())
                .padding()
            }
        }
        .onAppear {
            if let user = store.userProfile {
                manager.joinConvoy(id: convoyId, userId: user.id, userName: user.name)
            }
        }
        .onReceive(LocationManager.shared.$userLocation) { location in
            guard let location = location, let user = store.userProfile else { return }
            manager.updateLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                userId: user.id,
                convoyId: convoyId
            )
        }
        .onDisappear {
            manager.stopListening()
        }
    }
    
    private func sendPing(_ type: PingType) {
        guard let user = store.userProfile else { return }
        let loc = LocationManager.shared.userLocation?.coordinate
        manager.sendPing(
            type: type,
            memberId: user.id,
            memberName: user.name,
            lat: loc?.latitude ?? 0,
            lon: loc?.longitude ?? 0,
            convoyId: convoyId
        )
    }
    
    private func pingIcon(for type: PingType) -> String {
        switch type {
        case .stuck: return "exclamationmark.triangle.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .general: return "hand.wave.fill"
        case .alert: return "bell.fill"
        }
    }
    
    private func pingText(for type: PingType) -> String {
        switch type {
        case .stuck: return settings.t("أنا عالق، أحتاج مساعدة!")
        case .coffee: return settings.t("تعالوا نتقهوى هنا ☕️")
        case .general: return settings.t("أنا هنا!")
        case .alert: return settings.t("انتبهوا!")
        }
    }
}

struct PingButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
        }
    }
}
