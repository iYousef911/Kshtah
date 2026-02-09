//
//  SpotDetailView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//


import SwiftUI
import MapKit
import WeatherKit // NEW
import PhotosUI // NEW: Image Picker
import StoreKit // NEW: For App Review
import FirebaseAuth

struct SpotDetailView: View {
    @StateObject private var offlineMaps = OfflineMapManager.shared
    let spot: CampingSpot
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager // NEW: Added missing environment object
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
    @State private var newRating = 5
    
    @State private var showMapSelection = false
    @State private var showShareSheet = false
    @State private var shareImagePreview: UIImage?

    // Weather State
    @State private var temperature: String = "--"
    @State private var windSpeed: String = "--"
    @State private var rainChance: String = "--"
    @State private var aiInsight: String = "" // NEW: AI Insight text
    @State private var showConvoy = false // NEW: For Pro Convoy
    @State private var showGroupChat = false // NEW: Group Chat Room
    @State private var currentMoon: MoonPhase? // NEW: Live Moon Data
    @State private var isLoadingChatRoom = false // NEW: Loading state for chat room
    @State private var selectedChatRoom: ChatRoom? // NEW: Selected chat room
    
    // Messaging State
    @State private var navigateToChat = false
    @State private var otherUserThreadId: String?
    @State private var otherUserToChat: (id: String, name: String)?
    
    // Image Picking State
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            ScrollView {
                scrollContent
            }
            .sheet(isPresented: $showConvoy) {
                ConvoyDashboard(spot: spot)
            }
            .sheet(isPresented: $showShareSheet) {
                CustomShareSheet(spot: spot, imageToShare: shareImagePreview, weatherTemp: temperature)
            }
            .sheet(isPresented: $showGroupChat) {
                if isLoadingChatRoom {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        VStack {
                            ProgressView()
                                .tint(.white)
                            Text(settings.t("جاري تجهيز الغرفة..."))
                                .foregroundStyle(.white)
                                .padding(.top)
                        }
                    }
                } else if let room = selectedChatRoom {
                    NavigationStack { GroupChatView(room: room) }
                } else if let room = store.chatRooms.first(where: { $0.spotId == spot.id.uuidString }) {
                    NavigationStack { GroupChatView(room: room) }
                } else {
                    // Fallback: Show loading
                    ZStack {
                        Color.black.ignoresSafeArea()
                        VStack {
                            ProgressView()
                                .tint(.white)
                            Text(settings.t("جاري تجهيز الغرفة..."))
                                .foregroundStyle(.white)
                                .padding(.top)
                        }
                    }
                }
            }
            .navigationTitle("").toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
            .onAppear { store.loadComments(for: spot.id) }
            .task { await fetchWeatherData() }
        }
        .navigationDestination(isPresented: $navigateToChat) {
            if let threadId = otherUserThreadId, let otherUser = otherUserToChat {
                ChatDetailView(chat: ChatThread(
                    id: threadId,
                    otherUserName: otherUser.name,
                    otherUserImage: "person.circle.fill",
                    otherUserId: otherUser.id,
                    messages: [],
                    lastMessageText: "",
                    lastMessageTime: Date()
                ))
            }
        }
    }
    
    private var scrollContent: some View {
        VStack(spacing: 20) {
            SpotDetailHeader(spot: spot)
            
            SpotWeatherSummary(
                temperature: temperature,
                windSpeed: windSpeed,
                rainChance: rainChance
            )
            
            ProLockedView(feature: "ai_insight") {
                AIInsightView(
                    insight: aiInsight.isEmpty ? (spot.aiInsight ?? "") : aiInsight,
                    isPro: store.userProfile?.isPro ?? false
                )
                .padding(.horizontal)
            }
            
            ProLockedView(feature: "stargazing") {
                StargazingInsightView(
                    bortleScale: spot.bortleScale,
                    isPro: store.userProfile?.isPro ?? false,
                    moonOverride: currentMoon
                )
                .padding(.horizontal)
            }
            
            ProLockedView(feature: "packing_list") {
                PackingListView(
                    spot: spot,
                    temperature: Double(temperature.replacingOccurrences(of: "°C", with: "")) ?? 25.0,
                    isPro: store.userProfile?.isPro ?? false
                )
                .padding(.horizontal)
            }
            
            SpotMomentsSection(spot: spot)
            
            spotChatSection
            
            SpotWeatherAttribution()
            
            SpotActionButtons(
                spot: spot,
                showMapSelection: $showMapSelection,
                onDirections: { showMapSelection = true },
                onShare: generateShareImage,
                onShowConvoy: { showConvoy = true }
            )
            
            SpotCommentsSection(spot: spot, newCommentText: $newCommentText, newRating: $newRating, selectedItem: $selectedItem, selectedImageData: $selectedImageData, onSubmit: submitComment) { userId, userName in
                startChat(with: userId, userName: userName)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
    }
    
    private func fetchWeatherData() async {
        guard let weather = await WeatherManager.shared.getWeather(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude) else { return }
        
        let temp = weather.currentWeather.temperature.converted(to: .celsius).value
        let wind = weather.currentWeather.wind.speed.converted(to: .kilometersPerHour).value
        
        await MainActor.run {
            self.temperature = "\(Int(temp))°C"
            self.windSpeed = "\(Int(wind)) كم"
            self.rainChance = (weather.dailyForecast.first?.precipitationChance ?? 0) > 0 ? "\(Int((weather.dailyForecast.first?.precipitationChance ?? 0) * 100))%" : "0%"
            
            if let daily = weather.dailyForecast.first {
                let phase = daily.moon.phase
                let (name, icon) = MoonPhaseService.shared.mapWeatherKitPhase(phase)
                self.currentMoon = MoonPhase(phase: 0, name: name, icon: icon, illumination: 100)
            }
        }
        
        let moonToUse = currentMoon ?? MoonPhaseService.shared.getMoonPhase()
        let insight = await AIService.shared.generateInsight(
            spotName: spot.name,
            location: spot.location,
            temperature: temp, 
            condition: weather.currentWeather.condition.description,
            moonPhase: moonToUse.name,
            moonIllumination: moonToUse.illumination
        )
        
        await MainActor.run {
            withAnimation { self.aiInsight = insight }
        }
        
        store.createSpotChatIfNeeded(spotId: spot.id.uuidString, spotName: spot.name)
        store.fetchChatRooms()
    }
    
    private var spotChatSection: some View {
        Button(action: {
            ensureChatRoomExists()
        }) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title3)
                VStack(alignment: .leading) {
                    Text(settings.t("دردشة زوار المكان"))
                        .font(.headline)
                    Text(settings.t("تحدث مع أشخاص زاروا هذا المكان أو يخططون لزيارته"))
                        .font(.caption2)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.caption.bold())
            }
            .padding()
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(.white)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func submitComment() {
        if !newCommentText.isEmpty {
            store.addComment(spotId: spot.id, text: newCommentText, rating: newRating, imageData: selectedImageData)
            
            // NEW: Increment action counter for review prompt
            store.successfulActionsCount += 1
            
            if newRating >= 4 || store.successfulActionsCount >= 5 {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene { SKStoreReviewController.requestReview(in: scene) }
            }
            newCommentText = ""
            newRating = 5
            selectedItem = nil
            selectedImageData = nil
        }
    }
    
    private func generateShareImage() {
        Task { @MainActor in
            var loadedImage: UIImage? = nil
            if let urlStr = spot.imageURL, let url = URL(string: urlStr) {
                loadedImage = await Task.detached { if let (data, _) = try? await URLSession.shared.data(from: url) { return UIImage(data: data) }; return nil }.value
            }
            let renderer = ImageRenderer(content: ShareCardView(spot: spot, weatherTemp: temperature, loadedImage: loadedImage))
            renderer.scale = 3.0
            if let image = renderer.uiImage {
                shareImagePreview = image
                showShareSheet = true
            }
        }
    }
    
    enum MapApp { case apple, google, waze }
    
    func canOpen(app: MapApp) -> Bool {
        let scheme = app == .google ? "comgooglemaps://" : "waze://"
        return UIApplication.shared.canOpenURL(URL(string: scheme)!)
    }
    
    func openMap(app: MapApp) {
        let lat = spot.coordinate.latitude
        let long = spot.coordinate.longitude
        let urlString: String
        
        switch app {
        case .apple:
            urlString = "maps://?daddr=\(lat),\(long)"
        case .google:
             urlString = "comgooglemaps://?daddr=\(lat),\(long)&directionsmode=driving"
        case .waze:
            urlString = "waze://?ll=\(lat),\(long)&navigate=yes"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func ensureChatRoomExists() {
        if let existingRoom = store.chatRooms.first(where: { $0.spotId == spot.id.uuidString }) {
            selectedChatRoom = existingRoom
            showGroupChat = true
            return
        }
        
        isLoadingChatRoom = true
        showGroupChat = true
        
        store.getOrCreateSpotRoom(spotId: spot.id.uuidString, spotName: spot.name) { room in
            DispatchQueue.main.async {
                isLoadingChatRoom = false
                if let room = room {
                    selectedChatRoom = room
                } else {
                    showGroupChat = false
                }
            }
        }
    }
    
    private func startChat(with userId: String, userName: String) {
        guard userId != FirebaseManager.shared.user?.uid else { return }
        
        store.getChatThreadId(otherUserId: userId) { threadId in
            self.otherUserThreadId = threadId
            self.otherUserToChat = (id: userId, name: userName)
            self.navigateToChat = true
        }
    }
}

// MARK: - Dedicated Subviews

struct SpotDetailHeader: View {
    let spot: CampingSpot
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geometry in
                if let url = spot.imageURL, let validURL = URL(string: url) {
                    AsyncImage(url: validURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(.white.opacity(0.1))
                    }
                } else {
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "tent.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.2))
                        )
                }
            }
            .frame(height: 250)
            
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
            
            VStack(alignment: .leading, spacing: 5) {
                if !spot.type.isEmpty {
                    Text(spot.type)
                        .font(.caption)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(.capsule)
                        .foregroundStyle(.white)
                }
                Text(spot.name)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(spot.location)
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(spot.rating, format: .number.precision(.fractionLength(1)))
                    Text("(\(spot.numberOfRatings))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 250)
        .clipShape(.rect(cornerRadius: 30))
        .overlay {
            if spot.isProOnly && !(store.userProfile?.isPro ?? false) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial)
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill").font(.largeTitle)
                        Text(settings.t("هذه الكشتة حصرية لـ PRO")).font(.headline)
                        Button(action: { /* Navigate to Pro */ }) {
                            Text(settings.t("اشترك الآن للوصول"))
                                .bold()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .clipShape(.capsule)
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct SpotWeatherSummary: View {
    let temperature: String
    let windSpeed: String
    let rainChance: String

    var body: some View {
        HStack(spacing: 20) {
            WeatherColumn(icon: "sun.max.fill", value: temperature, label: "الحرارة")
            Divider().background(.white.opacity(0.3))
            
            ProLockedView(feature: "weather_details") {
                HStack(spacing: 20) {
                    WeatherColumn(icon: "wind", value: windSpeed, label: "الرياح")
                    Divider().background(.white.opacity(0.3))
                    WeatherColumn(icon: "drop.fill", value: rainChance, label: "المطر")
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
    }
}

struct SpotMomentsSection: View {
    let spot: CampingSpot
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedMomentItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settings.t("لحظات حية"))
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                
                PhotosPicker(selection: $selectedMomentItem, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text(settings.t("إضافة"))
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                    .padding(6)
                    .background(.white.opacity(0.1))
                    .clipShape(.capsule)
                }
                .onChange(of: selectedMomentItem) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            store.addMoment(spotId: spot.id, imageData: data, caption: nil)
                            selectedMomentItem = nil
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            if let moments = store.moments[spot.id], !moments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(moments) { moment in
                            VStack(alignment: .leading, spacing: 0) {
                                AsyncImage(url: URL(string: moment.imageURL)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Color.white.opacity(0.1)
                                }
                                .frame(width: 120, height: 160)
                                .clipped()
                                
                                HStack {
                                    Text(moment.userName)
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(moment.timeAgo)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(8)
                                .background(.black.opacity(0.6))
                            }
                            .clipShape(.rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text(settings.t("لا توجد لحظات بعد. كن أول من يشارك!"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct SpotWeatherAttribution: View {
    var body: some View {
        HStack(spacing: 4) {
            Text(" Weather")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Link("Legal", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                .font(.caption2)
                .underline()
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, -10)
        .padding(.bottom, 10)
    }
}

struct SpotActionButtons: View {
    let spot: CampingSpot
    @Binding var showMapSelection: Bool
    @EnvironmentObject var store: AppDataStore
    @StateObject private var offlineMaps = OfflineMapManager.shared
    
    var onDirections: () -> Void
    var onShare: () -> Void
    var onShowConvoy: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            Button(action: onDirections) {
                Label("اتجاهات", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(.capsule)
                    .foregroundStyle(.white)
            }
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(.circle)
                    .foregroundStyle(.white)
            }
            
            if store.userProfile?.isPro ?? false {
                Button(action: onShowConvoy) {
                    Image(systemName: "car.2.fill")
                        .padding()
                        .background(Color.blue)
                        .clipShape(.circle)
                        .foregroundStyle(.white)
                }
                
                Button(action: { offlineMaps.downloadMap(for: spot) }) {
                    ZStack {
                        if let progress = offlineMaps.downloadProgress[spot.id] {
                            ProgressView(value: progress)
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: offlineMaps.isDownloaded(spot.id) ? "checkmark.circle.fill" : "map.fill")
                                .padding()
                                .background(offlineMaps.isDownloaded(spot.id) ? Color.green : Color.blue)
                                .clipShape(.circle)
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SpotCommentsSection: View {
    let spot: CampingSpot
    @Binding var newCommentText: String
    @Binding var newRating: Int
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImageData: Data?
    @EnvironmentObject var store: AppDataStore
    
    var onSubmit: () -> Void
    var onChat: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("آراء الكشاتة")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                HStack {
                    Text("تقييمك:").font(.caption).foregroundStyle(.white.opacity(0.7))
                    ForEach(1...5, id: \.self) { star in 
                        Image(systemName: star <= newRating ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                            .onTapGesture { withAnimation { newRating = star } } 
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(.rect(cornerRadius: 12))
                        Button(action: { selectedItem = nil; selectedImageData = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .background(Color.white.clipShape(.circle))
                        }
                        .offset(x: 5, y: -5)
                    }
                    .padding(.horizontal, 12)
                }
                
                HStack {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.blue)
                            .padding(10)
                            .background(.white.opacity(0.1))
                            .clipShape(.circle)
                    }
                    .onChange(of: selectedItem) { _, newValue in
                        Task { if let data = try? await newValue?.loadTransferable(type: Data.self) { selectedImageData = data } }
                    }
                    
                    TextField("اكتب تجربتك...", text: $newCommentText)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.1))
                        .clipShape(.capsule)
                    
                    Button(action: onSubmit) { 
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.blue)
                            .padding(10)
                            .background(.white.opacity(0.1))
                            .clipShape(.circle) 
                    }
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .padding(.horizontal)
            
            Group {
                if let comments = store.comments[spot.id], !comments.isEmpty {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment) {
                            onChat(comment.userId, comment.userName)
                        }
                    }
                } else {
                    Text("كن أول من يقيم المكان!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal)
                }
            }
        }
    }
}


struct WeatherColumn: View { let icon: String, value: String, label: String; var body: some View { VStack(spacing: 4) { Image(systemName: icon).foregroundStyle(Color.yellow); Text(value).fontWeight(.bold).foregroundStyle(Color.white); Text(label).font(.caption).foregroundStyle(Color.white.opacity(0.6)) }.frame(maxWidth: .infinity) } }

struct CommentRow: View {
    let comment: Comment
    var onMessageTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: comment.userImage).font(.title2).foregroundStyle(Color.gray).frame(width: 40, height: 40).background(Color.white.opacity(0.1)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName).fontWeight(.bold).foregroundStyle(Color.white)
                    if comment.isAdmin { Image(systemName: "checkmark.shield.fill").foregroundStyle(Color.blue).font(.caption) }
                    if comment.isPro {
                        Text("PRO").font(.system(size: 8, weight: .black)).foregroundStyle(.white).padding(.horizontal, 4).padding(.vertical, 2)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Capsule())
                    }
                    if let r = comment.rating { HStack(spacing: 2) { Image(systemName: "star.fill").font(.caption2).foregroundStyle(Color.yellow); Text("\(r)").font(.caption2).foregroundStyle(Color.white) }.padding(.horizontal, 6).padding(.vertical, 2).background(Color.white.opacity(0.1)).clipShape(Capsule()) }
                    
                    Spacer()
                    
                    Button(action: { 
                        if comment.userId != FirebaseManager.shared.user?.uid {
                            onMessageTap?() 
                        }
                    }) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                            .foregroundStyle(comment.userId == FirebaseManager.shared.user?.uid ? Color.gray.opacity(0.3) : Color.blue)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(comment.userId == FirebaseManager.shared.user?.uid)
                    
                    Text(comment.timeAgo).font(.caption).foregroundStyle(Color.white.opacity(0.5))
                }
                Text(comment.text).font(.subheadline).foregroundStyle(Color.white.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                if let imageURL = comment.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.white.opacity(0.1) }
                        .frame(maxWidth: .infinity).frame(height: 150).clipped().clipShape(RoundedRectangle(cornerRadius: 12)).padding(.top, 4)
                }
            }
        }
        .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
    }
}

