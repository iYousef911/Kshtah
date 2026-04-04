//
//  HomeFeedView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager // NEW: Localization
    @Environment(\.horizontalSizeClass) var sizeClass // NEW: Responsive Layout
    @State private var showInbox = false
    @State private var showCompass = false
    @State private var showNotifications = false // NEW State
    @State private var showDiscountAlert = false // NEW: Discount Alert State
    @State private var showConvoy = false // NEW: For Pro Convoy
    @State private var showChatDashboard = false // NEW: Group Chat
    @State private var showAIItinerary = false // NEW: AI Itinerary
    @State private var weatherAlert: (type: String, speed: Int)? // NEW: Alert State
    @State private var selectedCategory = "الكل"

    // ... (rest of code)


    @State private var selectedSpot: CampingSpot? // NEW: State for spot selection
    
    // Live User Name (Defaults to "ضيف" if nil)
    var userName: String {
        store.userProfile?.name.components(separatedBy: " ").first ?? "ضيف"
    }
    
    let categories = ["الكل", "مخيمات", "كثبان", "وادي", "جبل", "شاطئ"]
    
    var filteredSpots: [CampingSpot] {
        if selectedCategory == "الكل" {
            return store.spots
        } else {
            return store.spots.filter { $0.type == selectedCategory }
        }
    }
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                // iPhone: Standard Stack
                NavigationStack {
                    HomeFeedContent(
                        showInbox: $showInbox,
                        showCompass: $showCompass,
                        showNotifications: $showNotifications,
                        showDiscountAlert: $showDiscountAlert,
                        selectedCategory: $selectedCategory,
                        selectedSpot: $selectedSpot,
                        showConvoy: $showConvoy,
                        showChatDashboard: $showChatDashboard,
                        showAIItinerary: $showAIItinerary,
                        weatherAlert: $weatherAlert
                    )
                    .sheet(item: $selectedSpot) { spot in // Sheet only on iPhone
                        SpotDetailView(spot: spot)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                    }
                    .sheet(isPresented: $showConvoy) {
                        ConvoyDashboard()
                    }
                    .sheet(isPresented: $showChatDashboard) {
                        GroupChatDashboard()
                    }
                }
            } else {
                // iPad: Native Split View
                NavigationSplitView {
                    HomeFeedContent(
                        showInbox: $showInbox,
                        showCompass: $showCompass,
                        showNotifications: $showNotifications,
                        showDiscountAlert: $showDiscountAlert,
                        selectedCategory: $selectedCategory,
                        selectedSpot: $selectedSpot,
                        showConvoy: $showConvoy,
                        showChatDashboard: $showChatDashboard,
                        showAIItinerary: $showAIItinerary,
                        weatherAlert: $weatherAlert
                    )
                    .navigationTitle("Home")
                    .navigationBarHidden(true)
                    .sheet(isPresented: $showConvoy) {
                        ConvoyDashboard()
                    }
                    .sheet(isPresented: $showChatDashboard) {
                        GroupChatDashboard()
                    }
                } detail: {
                    ZStack {
                        LiquidBackgroundView()
                        if let spot = selectedSpot {
                            SpotDetailView(spot: spot)
                                .id(spot.id) // Force refresh on change
                        } else {
                            ContentUnavailableView(
                                "Select a camping spot",
                                systemImage: "tent.fill",
                                description: Text("Choose a spot from the list to view details.")
                            )
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .trackScreen(name: "Home") // Analytic Screen
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SevereWeatherAlert"))) { note in
            if let info = note.userInfo as? [String: Any],
               let type = info["type"] as? String,
               let speed = info["speed"] as? Int {
                withAnimation {
                    self.weatherAlert = (type: type, speed: speed)
                }
            }
        }
        .sheet(isPresented: $showAIItinerary) {
            AIItineraryView()
        }
    }

    // Action Logic
    func useDiscount() {
        UIPasteboard.general.string = store.discountCode
        showDiscountAlert = true
    }
    
    func getIconForCategory(_ category: String) -> String {
        switch category {
        case "الكل": return "square.grid.2x2.fill"
        case "مخيمات": return "tent.fill"
        case "كثبان": return "wind"
        case "وادي": return "water.waves"
        case "جبل": return "mountain.2.fill"
        case "شاطئ": return "sun.max.fill"
        default: return "mappin.and.ellipse"
        }
    }
}

// Extracted Content View
struct HomeFeedContent: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var theme: ThemeManager
    
    @Binding var showInbox: Bool
    @Binding var showCompass: Bool
    @Binding var showNotifications: Bool
    @Binding var showDiscountAlert: Bool
    @Binding var selectedCategory: String
    @Binding var selectedSpot: CampingSpot?
    @Binding var showConvoy: Bool
    @Binding var showChatDashboard: Bool // NEW: Binding
    @Binding var showAIItinerary: Bool
    @Binding var weatherAlert: (type: String, speed: Int)?
    @StateObject private var nativeAdViewModel = NativeAdViewModel()
    
    // Live User Name
    var userName: String {
        store.userProfile?.name.components(separatedBy: " ").first ?? "ضيف"
    }
    
    // REMOVED: let categories = [...] (Now using store.categories)
    
    var filteredSpots: [CampingSpot] {
        if selectedCategory == "الكل" {
            return store.spots
        } else {
            // Updated filtering logic for dynamic types
            return store.spots.filter { $0.type == selectedCategory }
        }
    }
    
    var specialSpots: [CampingSpot] {
        filteredSpots.filter { $0.isSpecial }
    }
    
    var regularSpots: [CampingSpot] {
        filteredSpots.filter { !$0.isSpecial }
    }
    
    // Helper to get icon (duplicated logic for simplicity in extraction or moved to shared)
    
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ZStack {
            // Mobile Background with Particles
            if sizeClass == .compact {
                ParticleEffectView()
                    .zIndex(0)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Weather Alert Banner
                    if let alert = weatherAlert {
                        // ... (keep existing alert code)
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading) {
                                Text(settings.t("تحذير من رياح قوية!"))
                                    .font(.headline)
                                Text("\(settings.t("سرعة الرياح بلغت")) \(alert.speed) \(settings.t("كم/س. انتبه على خيمتك!"))")
                                    .font(.caption)
                            }
                            Spacer()
                            Button(action: { weatherAlert = nil }) {
                                Image(systemName: "xmark").font(.caption).padding(8).background(.white.opacity(0.1)).clipShape(Circle())
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Header with Parallax & Fade
                    GeometryReader { geo in
                        let minY = geo.frame(in: .global).minY
                        let opacity = max(0, min(1, (minY + 20) / 50)) // Fade out as you scroll up
                        
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(settings.t("مرحباً،") + " \(userName) 👋")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(Color.white)
                                    
                                    if store.currentTheme == .foundingDay {
                                        FoundingDayBadge()
                                            .scaleEffect(0.6)
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                    if store.userProfile?.isAdmin == true {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundStyle(store.appColor)
                                    }
                                }
                                Text(settings.t(store.homeTitleText))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                            Spacer()
                            
                            // Action Buttons
                            HStack(spacing: 4) {
                                Button(action: { showCompass = true }) {
                                    Image(systemName: "safari.fill")
                                        .padding(12)
                                        .foregroundStyle(Color.white)
                                }
                                
                                Button(action: { showChatDashboard = true }) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .padding(12)
                                        .foregroundStyle(Color.white)
                                }
                                
                                Button(action: { showInbox = true }) {
                                    Image(systemName: "envelope.badge.fill")
                                        .padding(12)
                                        .foregroundStyle(Color.white)
                                }
                                
                                Button(action: { showNotifications = true }) {
                                    Image(systemName: "bell.badge.fill")
                                        .padding(12)
                                        .foregroundStyle(Color.white)
                                }
                                
                                if store.userProfile?.isPro ?? false {
                                    Button(action: { showConvoy = true }) {
                                        Image(systemName: "car.2.fill")
                                            .padding(12)
                                            .foregroundStyle(Color.white)
                                    }
                                }
                            }
                            .glassEffect(GlassStyle.regular.interactive(), in: Capsule())
                        }
                        .padding(.horizontal)
                        .opacity(opacity) // Apply Fade
                        .scaleEffect(0.9 + (0.1 * opacity)) // Subtle Scale
                    }
                    .frame(height: 60) // Fixed height placeholder
                    .zIndex(1)
                    
                    
                    // Categories (Entrance Animation 1)
                    ScrollView(.horizontal) {
                        HStack(spacing: 15) {
                            ForEach(Array(store.categories.enumerated()), id: \.element.id) { index, category in
                                Button(action: {
                                    withAnimation { selectedCategory = category.type }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    CategoryGlassPill(
                                        icon: category.icon,
                                        title: settings.t(category.name),
                                        isSelected: selectedCategory == category.type,
                                        activeColor: store.appColor
                                    )
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: true) // Staggered
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollIndicators(.hidden)
                    
                    // AI Itinerary Master (PRO ONLY)
                    if store.userProfile?.isPro ?? false {
                        Button(action: { showAIItinerary = true }) {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "sparkles")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(settings.t("خبير الكشتات الذكي"))
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(settings.t("خل الذكاء الاصطناعي يجهز لك أحلى عطلة نهاية أسبوع!"))
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding()
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
                        }
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Discount Banner
                    if store.showDiscountBanner {
                        // ... (keep existing banner code)
                        HStack {
                            VStack(alignment: .leading) {
                                Text(settings.t("عرض خاص! 🎉"))
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                Text(settings.t("خصم 10% على أول كشتة"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            Spacer()
                            Button(settings.t("استخدمه الآن")) {
                                useDiscount()
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundStyle(store.appColor)
                            .clipShape(Capsule())
                        }
                        .padding()
                        .background(
                            LinearGradient(colors: [store.appColor.opacity(0.8), store.appColor.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    // (Standalone AdMob Banner removed, now interleaved in spots list)
                        
                    // NEW: Smart Recommendations Section (Entrance Animation 2)
                    if !store.recommendedSpots.isEmpty {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(settings.t("🌞 كشتة الويكند"))
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.white)
                                Spacer()
                                // Shimmering AI Badge
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text(settings.t("مدعوم بالذكاء"))
                                }
                                .font(.caption)
                                .foregroundStyle(Color.yellow)
                                .padding(6)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(LinearGradient(colors: [.clear, .white.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                                        .mask(
                                            GeometryReader { geo in
                                                if #available(iOS 17.0, *) {
                                                    Rectangle()
                                                        .fill(LinearGradient(colors: [.clear, .white, .clear], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: 50)
                                                        .phaseAnimator([false, true]) { view, phase in
                                                            view.offset(x: phase ? geo.size.width : -geo.size.width)
                                                        } animation: { _ in
                                                            .linear(duration: 2).repeatForever(autoreverses: false)
                                                        }
                                                } else {
                                                    Rectangle()
                                                        .fill(LinearGradient(colors: [.clear, .white, .clear], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: 50)
                                                }
                                            }
                                        )
                                )
                            }
                            .padding(.horizontal)
                            
                            Text(settings.t("اخترنا لك أفضل الأماكن بناءً على الطقس في عطلة نهاية الأسبوع!"))
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.7))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal) {
                                HStack(spacing: 15) {
                                    ForEach(Array(store.recommendedSpots.enumerated()), id: \.element.id) { index, rec in
                                        RecommendationCard(recommendation: rec)
                                            .onTapGesture {
                                                selectedSpot = rec.spot
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                            }
                                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: true) // Cascade
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                    // Featured Spots Section
                    if !filteredSpots.isEmpty {
                        Text(settings.t("أماكن مميزة"))
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal)
                        
                        // First loop through special spots
                        ForEach(Array(specialSpots.enumerated()), id: \.element.id) { index, spot in
                            GlassSpotCard(spot: spot)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSpot = spot
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                        
                        // Then loop through regular spots, keeping ad injection tracking
                        ForEach(Array(regularSpots.enumerated()), id: \.element.id) { index, spot in
                            GlassSpotCard(spot: spot)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSpot = spot
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                                
                            // Inject Native Ad every 4 spots (after 3rd, 7th, 11th...) ONLY for free users
                            if !(store.userProfile?.isPro ?? false) && (index + 1) % 4 == 0 {
                                let adIndex = index / 4
                                if !nativeAdViewModel.nativeAds.isEmpty {
                                    // Loop through available ads
                                    let safeIndex = adIndex % nativeAdViewModel.nativeAds.count
                                    AdMobNativeView(nativeAd: nativeAdViewModel.nativeAds[safeIndex])
                                        .frame(height: 110) // Matches GlassSpotCard approximate height
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                        .transition(.opacity)
                                } else if nativeAdViewModel.isLoading {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(height: 110)
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "mappin.slash.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.white.opacity(0.3))
                            Text(settings.t("لا توجد أماكن في هذا التصنيف"))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                    
                    // Recommended Gear Section
                    if selectedCategory == "الكل" && store.isMarketplaceEnabled {
                        Text(settings.t("معدات مقترحة"))
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 15) {
                                ForEach(store.gear.prefix(5)) { item in
                                    NavigationLink(destination: ProductDetailView(item: item)) {
                                        GearMiniCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.top)
                .padding(.bottom, 100)
                .onAppear {
                    nativeAdViewModel.refreshAd()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            store.fetchSpots()
            store.fetchCategories() // NEW: Refresh categories
        }
        .sheet(isPresented: $showInbox) { MessagesView().presentationDetents([.large]) }
        .sheet(isPresented: $showNotifications) { NotificationsView().presentationDetents([.medium]).environmentObject(store).environmentObject(settings).environmentObject(theme) }
        .fullScreenCover(isPresented: $showCompass) { ARQiblaView().environmentObject(store).environmentObject(settings).environmentObject(theme) }
        .alert(settings.t("نسخنا لك كود الخصم! 🎁"), isPresented: $showDiscountAlert) {
            Button(settings.t("شكراً"), role: .cancel) { }
        } message: {
            Text("\(settings.t("تم نسخ كود")) (\(store.discountCode)) \(settings.t("للحافظة. استمتع بكشتتك!"))")
    }
    } // End of body

    // Action Logic
    func useDiscount() {
        UIPasteboard.general.string = store.discountCode
        showDiscountAlert = true
    }
} // End of HomeFeedContent

struct CategoryGlassPill: View {
        let icon: String, title: String, isSelected: Bool
        var activeColor: Color = .blue // Default fallback
        
        var body: some View {
            HStack { Image(systemName: icon); Text(title) }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .glassEffect(isSelected ? GlassStyle.regular.interactive().tint(activeColor.opacity(0.3)) : GlassStyle.regular.interactive(), in: Capsule())
                .foregroundStyle(Color.white)
        }
    }
    
    struct GearMiniCard: View {
        let item: GearItem
        var body: some View {
            VStack(alignment: .leading) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)).frame(width: 120, height: 100)
                    Image(systemName: item.imageName).font(.largeTitle).foregroundStyle(Color.white)
                }
                Text(item.name).font(.caption).fontWeight(.bold).foregroundStyle(Color.white).lineLimit(1).frame(width: 120, alignment: .leading)
                Text("\(item.pricePerDay) ﷼/يوم").font(.caption2).foregroundStyle(Color.green)
            }
        }
    }
    
    // NEW: Notifications View
    struct NotificationsView: View {
        @Environment(\.dismiss) var dismiss
        @EnvironmentObject var settings: SettingsManager
        
        var body: some View {
            ZStack {
                LiquidBackgroundView()
                ParticleEffectView().opacity(0.5) // Subtle particles
                
                VStack {
                    // Header
                    HStack {
                        Spacer()
                        Text(settings.t("الإشعارات"))
                            .font(.headline)
                            .foregroundStyle(Color.white)
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Image(systemName: "bell.slash.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .scaleEffect(1.1)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
                        
                        Text(settings.t("لا توجد إشعارات جديدة"))
                            .font(.headline)
                            .foregroundStyle(Color.white.opacity(0.6))
                        
                        Text(settings.t("سنخبرك عند وجود عروض جديدة"))
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    
                    Spacer()
                }
            }
        }
    }




#Preview {
    HomeFeedView()
        .environmentObject(AppDataStore())
        .environmentObject(SettingsManager())
        .environmentObject(ThemeManager())
}
