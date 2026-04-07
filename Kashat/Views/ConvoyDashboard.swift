import SwiftUI
import MapKit
import AudioToolbox
import StoreKit

struct ConvoyDashboard: View {
    @StateObject private var voiceManager = VoiceNoteManager() // NEW: Audio Manager
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
                        if lastPing.type == .audio {
                            // Audio Player View
                            HStack {
                                Image(systemName: "mic.fill")
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(lastPing.memberName)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                    if let text = lastPing.transcribedText {
                                        Text(text) // Display Transcription
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                    } else {
                                        Text("رسالة صوتية 🎙️")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if let url = lastPing.audioURL {
                                        voiceManager.playRemoteAudio(urlString: url)
                                    }
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                        } else {
                            Image(systemName: pingIcon(for: lastPing.type))
                                .foregroundStyle(.red)
                            VStack(alignment: .leading) {
                                Text(lastPing.memberName)
                                    .font(.caption.bold())
                                Text(pingText(for: lastPing.type))
                                    .font(.caption2)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(lastPing.id) // Force refresh on new ping
                }
                
                // Action Bar (Walkie-Talkie)
                HStack(spacing: 20) {
                    // Quick Pings (Mini)
                    VStack(spacing: 10) {
                        MiniPingButton(icon: "exclamationmark.triangle.fill", color: .red) { sendPing(.stuck) }
                        MiniPingButton(icon: "cup.and.saucer.fill", color: .orange) { sendPing(.coffee) }
                    }
                                        
                    Spacer()
                    
                    // BIG Push-to-Talk Button
                    VStack {
                        Text(voiceManager.isRecording ? "إطلاق للإرسال" : "إضغط للتحدث")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .opacity(0.8)
                        
                        ZStack {
                            Circle()
                                .fill(voiceManager.isRecording ? Color.red : Color.blue)
                                .frame(width: 80, height: 80)
                                .shadow(color: voiceManager.isRecording ? .red.opacity(0.5) : .blue.opacity(0.5), radius: 10)
                                .scaleEffect(voiceManager.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: voiceManager.isRecording)
                            
                            Image(systemName: "mic.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !voiceManager.isRecording {
                                        startRecording()
                                    }
                                }
                                .onEnded { _ in
                                    if voiceManager.isRecording {
                                        stopRecordingAndSend()
                                    }
                                }
                        )
                    }
                    
                    Spacer()
                    
                    // Info
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
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 25))
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            if let user = store.userProfile {
                manager.joinConvoy(id: convoyId, userId: user.id, userName: user.name)
            }
        }
        .onChange(of: store.userProfile) { oldProfile, newProfile in
            if let user = newProfile {
                manager.joinConvoy(id: convoyId, userId: user.id, userName: user.name)
            }
        }
        .onReceive(LocationManager.shared.$userLocation) { location in
            guard let location = location, let user = store.userProfile else { return }
            manager.updateLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                userId: user.id,
                userName: user.name,
                convoyId: convoyId
            )
        }
        .onDisappear {
            manager.stopListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewConvoyPing"))) { _ in
            triggerFeedback(isOutgoing: false)
            
            // Auto-play audio if new ping is audio
            if let latest = manager.pings.first, latest.type == .audio, let url = latest.audioURL {
                 // Optional: Auto-play logic could go here, but usually risky for UX. Let's stick to manual play or just sound effect.
            }
        }
    }
    
    // MARK: - Audio Logic
    private func startRecording() {
        triggerFeedback(isOutgoing: true)
        voiceManager.startRecording()
    }
    
    private func stopRecordingAndSend() {
        voiceManager.stopRecording { url, duration in
            guard let url = url, let user = store.userProfile else { return }
            
            // Minimum duration check
            if duration < 0.5 { return }
            
            // AI Transcription
            voiceManager.transcribeAudio(url: url) { transcribedText in
                // Send with transcription
                manager.sendAudioPing(
                    url: url,
                    duration: duration,
                    memberId: user.id,
                    memberName: user.name,
                    lat: LocationManager.shared.userLocation?.coordinate.latitude ?? 0,
                    lon: LocationManager.shared.userLocation?.coordinate.longitude ?? 0,
                    convoyId: convoyId,
                    transcribedText: transcribedText // Pass Text
                )
            }
            
            triggerFeedback(isOutgoing: true)
        }
    }
    
    private func triggerFeedback(isOutgoing: Bool) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        // Play system sound: 1004 is 'Sent Message', 1003 is 'Received Message'
        let soundId: SystemSoundID = isOutgoing ? 1113 : 1114 // Walkie Talkie sounds (approximated)
        AudioServicesPlaySystemSound(soundId)
    }
    
    private func sendPing(_ type: PingType) {
        guard let user = store.userProfile else { return }
        triggerFeedback(isOutgoing: true)
        let loc = LocationManager.shared.userLocation?.coordinate
        manager.sendPing(
            type: type,
            memberId: user.id,
            memberName: user.name,
            lat: loc?.latitude ?? 0,
            lon: loc?.longitude ?? 0,
            convoyId: convoyId
        )
        
        // NEW: Strategic Review Prompt
        store.successfulActionsCount += 1
        if store.successfulActionsCount >= 3 {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        }
    }
    
    private func pingIcon(for type: PingType) -> String {
        switch type {
        case .stuck: return "exclamationmark.triangle.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .general: return "hand.wave.fill"
        case .alert: return "bell.fill"
        case .audio: return "mic.fill"
        }
    }
    
    private func pingText(for type: PingType) -> String {
        switch type {
        case .stuck: return settings.t("أنا عالق، أحتاج مساعدة!")
        case .coffee: return settings.t("تعالوا نتقهوى هنا ☕️")
        case .general: return settings.t("أنا هنا!")
        case .alert: return settings.t("انتبهوا!")
        case .audio: return settings.t("رسالة صوتية")
        }
    }
}

struct MiniPingButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.8))
                .clipShape(Circle())
        }
    }
}
