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
                        selectedSpot: $selectedSpot
                    )
                    .sheet(item: $selectedSpot) { spot in // Sheet only on iPhone
                        SpotDetailView(spot: spot)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
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
                        selectedSpot: $selectedSpot
                    )
                    .navigationTitle("Home")
                    .navigationBarHidden(true)
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
    
    @Binding var showInbox: Bool
    @Binding var showCompass: Bool
    @Binding var showNotifications: Bool
    @Binding var showDiscountAlert: Bool
    @Binding var selectedCategory: String
    @Binding var selectedSpot: CampingSpot?
    
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
    
    // Helper to get icon (duplicated logic for simplicity in extraction or moved to shared)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(settings.t("مرحباً،") + " \(userName) 👋")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.white)
                            if store.userProfile?.isAdmin == true {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(Color.blue)
                            }
                        }
                        Text(settings.t(store.homeTitleText))
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Spacer()
                    
                    Button(action: { showCompass = true }) {
                        Image(systemName: "safari.fill")
                            .padding(12)
                            .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                            .foregroundStyle(Color.white)
                    }
                    
                    Button(action: { showInbox = true }) {
                        Image(systemName: "envelope.badge.fill")
                            .padding(12)
                            .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                            .foregroundStyle(Color.white)
                    }
                    
                    Button(action: { showNotifications = true }) {
                        Image(systemName: "bell.badge.fill")
                            .padding(12)
                            .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.horizontal)
                
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Dynamic Categories Loop
                        ForEach(store.categories) { category in
                            Button(action: {
                                withAnimation { selectedCategory = category.type }
                            }) {
                                CategoryGlassPill(
                                    icon: category.icon,
                                    title: settings.t(category.name),
                                    isSelected: selectedCategory == category.type,
                                    activeColor: store.appColor
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Discount Banner
                if store.showDiscountBanner {
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
                            // Action placeholder
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
                
                // NEW: Smart Recommendations Section
                if !store.recommendedSpots.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(settings.t("🌞 كشتة الويكند"))
                                .font(.title2.bold())
                                .foregroundStyle(Color.white)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text(settings.t("مدعوم بالذكاء"))
                            }
                            .font(.caption)
                            .foregroundStyle(Color.yellow)
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        Text(settings.t("اخترنا لك أفضل الأماكن بناءً على الطقس في عطلة نهاية الأسبوع!"))
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.7))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(store.recommendedSpots) { rec in
                                    RecommendationCard(recommendation: rec)
                                        .onTapGesture {
                                            selectedSpot = rec.spot
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                // Featured Spots Section
                if !filteredSpots.isEmpty {
                    Text(settings.t("أماكن مميزة"))
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal)
                    
                    ForEach(filteredSpots) { spot in
                        GlassSpotCard(spot: spot)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSpot = spot
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
                    
                    ScrollView(.horizontal, showsIndicators: false) {
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
                }
            }
            .padding(.top)
            .padding(.bottom, 100)
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            store.fetchSpots()
            store.fetchCategories() // NEW: Refresh categories
        }
        .sheet(isPresented: $showInbox) { InboxView().presentationDetents([.large]) }
        .sheet(isPresented: $showNotifications) { NotificationsView().presentationDetents([.medium]) }
        .fullScreenCover(isPresented: $showCompass) { ARQiblaView() }
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
}
