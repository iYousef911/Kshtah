//
//  SpotDetailView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//


import SwiftUI
import SwiftUI
import MapKit
import WeatherKit // NEW
import PhotosUI // NEW: Image Picker
import StoreKit // NEW: For App Review

struct SpotDetailView: View {
    let spot: CampingSpot
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager // NEW: Added missing environment object
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
    @State private var newRating = 5
    
    @State private var showMapSelection = false
    @State private var showShareSheet = false // NEW
    @State private var shareImagePreview: UIImage? // NEW

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
    }
    
    private var scrollContent: some View {
        VStack(spacing: 20) {
            headerSection
            weatherSection
            
            ProLockedView(feature: "ai_insight") {
                aiInsightSection
            }
            
            ProLockedView(feature: "stargazing") {
                stargazingSection
            }
            
            ProLockedView(feature: "packing_list") {
                packingSection
            }
            
            spotChatSection
            
            attributionSection
            actionsSection
            commentsSection
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
    
    // MARK: - Sub-Views
    
    private var headerSection: some View {
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
                            .fill(Color.white.opacity(0.1))
                    }
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "tent.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.white.opacity(0.2))
                        )
                }
            }
            .frame(height: 250)
            
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
            
            VStack(alignment: .leading, spacing: 5) {
                if !spot.type.isEmpty {
                    Text(spot.type).font(.caption).padding(6).background(Color.blue).clipShape(Capsule()).foregroundStyle(Color.white)
                }
                Text(spot.name).font(.largeTitle).fontWeight(.bold).foregroundStyle(Color.white)
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(spot.location)
                    Spacer()
                    Image(systemName: "star.fill").foregroundStyle(Color.yellow)
                    Text("\(spot.rating, specifier: "%.1f")")
                    Text("(\(spot.numberOfRatings))")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .foregroundStyle(Color.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay {
            if spot.isProOnly && !(store.userProfile?.isPro ?? false) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial)
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill").font(.largeTitle)
                        Text(settings.t("هذه الكشتة حصرية لـ PRO")).font(.headline)
                        Button(action: { /* Navigate to Pro */ }) {
                            Text(settings.t("اشترك الآن للوصول")).fontWeight(.bold).padding(.horizontal, 20).padding(.vertical, 10).background(Color.blue).clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var weatherSection: some View {
        HStack(spacing: 20) {
            WeatherColumn(icon: "sun.max.fill", value: temperature, label: "الحرارة")
            Divider().background(Color.white.opacity(0.3))
            
            ProLockedView(feature: "weather_details") {
                HStack(spacing: 20) {
                    WeatherColumn(icon: "wind", value: windSpeed, label: "الرياح")
                    Divider().background(Color.white.opacity(0.3))
                    WeatherColumn(icon: "drop.fill", value: rainChance, label: "المطر")
                }
            }
        }
        .padding().glassEffect(GlassStyle.regular, in: Capsule()).padding(.horizontal)
    }
    
    private var aiInsightSection: some View {
        AIInsightView(
            insight: aiInsight.isEmpty ? (spot.aiInsight ?? "") : aiInsight,
            isPro: store.userProfile?.isPro ?? false
        )
        .padding(.horizontal)
    }
    
    private var stargazingSection: some View {
        StargazingInsightView(
            bortleScale: spot.bortleScale,
            isPro: store.userProfile?.isPro ?? false,
            moonOverride: currentMoon
        )
        .padding(.horizontal)
    }
    
    private var packingSection: some View {
        PackingListView(
            spot: spot,
            temperature: Double(temperature.replacingOccurrences(of: "°C", with: "")) ?? 25.0,
            isPro: store.userProfile?.isPro ?? false
        )
        .padding(.horizontal)
    }
    
    private var attributionSection: some View {
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
    
    private var actionsSection: some View {
        HStack(spacing: 15) {
            Button(action: {
                showMapSelection = true
            }) {
                Label("اتجاهات", systemImage: "arrow.triangle.turn.up.right.circle.fill").font(.headline).padding().frame(maxWidth: .infinity).background(Color.blue).clipShape(Capsule()).foregroundStyle(Color.white)
            }
            .confirmationDialog("اختر التطبيق", isPresented: $showMapSelection, titleVisibility: .visible) {
                Button("Apple Maps") { openMap(app: .apple) }
                if canOpen(app: .google) { Button("Google Maps") { openMap(app: .google) } }
                if canOpen(app: .waze) { Button("Waze") { openMap(app: .waze) } }
                Button("إلغاء", role: .cancel) { }
            }
            
                    Button(action: {
                        generateShareImage()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundStyle(Color.white)
                    }
                    
                    if store.userProfile?.isPro ?? false {
                        Button(action: { showConvoy = true }) {
                            Image(systemName: "car.2.fill")
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .foregroundStyle(Color.white)
                        }
                    }
                }
                .padding(.horizontal)
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("آراء الكشاتة").font(.headline).foregroundStyle(Color.white).padding(.horizontal)
            
            VStack(spacing: 10) {
                HStack {
                    Text("تقييمك:").font(.caption).foregroundStyle(Color.white.opacity(0.7))
                    ForEach(1...5, id: \.self) { star in Image(systemName: star <= newRating ? "star.fill" : "star").foregroundStyle(Color.yellow).onTapGesture { withAnimation { newRating = star } } }
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 12))
                        Button(action: { selectedItem = nil; selectedImageData = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.red).background(Color.white.clipShape(Circle()))
                        }.offset(x: 5, y: -5)
                    }.padding(.horizontal, 12)
                }

                HStack {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "camera.fill").foregroundStyle(Color.blue).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
                    }
                    .onChange(of: selectedItem) { _, newValue in
                        Task { if let data = try? await newValue?.loadTransferable(type: Data.self) { selectedImageData = data } }
                    }
                    
                    TextField("اكتب تجربتك...", text: $newCommentText).foregroundStyle(Color.white).padding(10).background(Color.white.opacity(0.1)).clipShape(Capsule())
                    
                    Button(action: submitComment) { 
                        Image(systemName: "paperplane.fill").foregroundStyle(Color.blue).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle()) 
                    }
                }
            }
            .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
            
            commentList
        }
        .padding(.bottom, 50)
    }
    
    private var commentList: some View {
        Group {
            if let comments = store.comments[spot.id], !comments.isEmpty {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            } else {
                Text("كن أول من يقيم المكان!").font(.caption).foregroundStyle(Color.white.opacity(0.5)).padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func submitComment() {
        if !newCommentText.isEmpty {
            store.addComment(spotId: spot.id, text: newCommentText, rating: newRating, imageData: selectedImageData)
            if newRating >= 4 {
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
    
    // MARK: - Chat Room Helper
    private func ensureChatRoomExists() {
        // Check if room already exists in the list
        if let existingRoom = store.chatRooms.first(where: { $0.spotId == spot.id.uuidString }) {
            selectedChatRoom = existingRoom
            showGroupChat = true
            return
        }
        
        // Show loading state
        isLoadingChatRoom = true
        showGroupChat = true
        
        // Get or create the room
        store.getOrCreateSpotRoom(spotId: spot.id.uuidString, spotName: spot.name) { room in
            DispatchQueue.main.async {
                isLoadingChatRoom = false
                if let room = room {
                    selectedChatRoom = room
                } else {
                    // Failed to create room, close sheet
                    showGroupChat = false
                }
            }
        }
    }
}


struct WeatherColumn: View { let icon: String, value: String, label: String; var body: some View { VStack(spacing: 4) { Image(systemName: icon).foregroundStyle(Color.yellow); Text(value).fontWeight(.bold).foregroundStyle(Color.white); Text(label).font(.caption).foregroundStyle(Color.white.opacity(0.6)) }.frame(maxWidth: .infinity) } }

struct CommentRow: View {
    let comment: Comment
    
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

