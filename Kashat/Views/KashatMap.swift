//
//  KashatMap.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import MapKit
import WeatherKit

struct KashatMap: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var showAddSpotSheet = false
    @State private var showSpotDetailSheet = false
    
    @State private var position: MapCameraPosition = .userLocation(
        fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        )
    )
    @State private var currentCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753)
    @State private var selectedSpot: CampingSpot?
    
    @State private var isAddMode = false
    @State private var showLocationError = false
    @State private var locationManager = CLLocationManager()
    
    // NEW: Search & Filter
    @State private var searchText = ""
    @State private var selectedCategories: Set<String> = []
    @State private var showProOnly = false // NEW: Pro Filter
    
    // NEW: Map Style
    @State private var currentMapStyle: MapStyleOption = .hybrid
    @State private var showMapStylePicker = false
    
    // NEW: Animation
    @State private var markersLoaded = false
    
    // NEW: Convoy Integration
    @StateObject private var convoyManager = ConvoyManager()
    @State private var showConvoyMembers = true
    
    // NEW: Weather Intel
    @State private var currentWeather: Weather?
    @State private var weatherTimer: Timer?
    @State private var showWeatherAlert = false
    @State private var severeWeatherInfo: [String: Any]?
    
    // NEW: Map Perspective
    @State private var is3DMode = false
    
    enum MapStyleOption: String, CaseIterable {
        case hybrid = "قمر صناعي"
        case standard = "عادي"
        case imagery = "صور"
        
        var style: MapStyle {
            switch self {
            case .hybrid: return .hybrid(elevation: .realistic)
            case .standard: return .standard(elevation: .realistic)
            case .imagery: return .imagery(elevation: .realistic)
            }
        }
        
        var icon: String {
            switch self {
            case .hybrid: return "globe.americas.fill"
            case .standard: return "map.fill"
            case .imagery: return "photo.fill"
            }
        }
    }
    
    // Filtered spots based on search and category
    var filteredSpots: [CampingSpot] {
        store.spots.filter { spot in
            let matchesSearch = searchText.isEmpty || spot.name.localizedCaseInsensitiveContains(searchText) || spot.location.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategories.isEmpty || selectedCategories.contains(spot.type)
            let matchesPro = !showProOnly || spot.isProOnly // Filter for Pro
            
            return matchesSearch && matchesCategory && matchesPro
        }
    }
    
    // Available categories from spots
    var availableCategories: [String] {
        Array(Set(store.spots.map { $0.type })).sorted()
    }
    
    var body: some View {
        ZStack {
            // 1. Map
            Map(position: $position, selection: $selectedSpot) {
                mapContent
            }
            .mapStyle(currentMapStyle.style)
            .onMapCameraChange { context in
                currentCenter = context.camera.centerCoordinate
            }
            .onChange(of: selectedSpot) { _, newSpot in
                if newSpot != nil {
                    if sizeClass == .compact {
                        showSpotDetailSheet = true
                    } else {
                        showSpotDetailSheet = false
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            
            searchAndFilterOverlay
            
            if sizeClass == .regular, let spot = selectedSpot {
                ipadSidePanel(for: spot)
            }

            if isAddMode {
                centerCrosshair
            }
            
            rightSideButtons
            bottomControls
            
            if !isAddMode && sizeClass == .compact {
                iphoneDetailCard
            }
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            
            // Join active convoy if available
            if let user = store.userProfile {
                let convoyId = "global_convoy" // Fallback or logic to get active convoy
                convoyManager.joinConvoy(id: convoyId, userId: user.id, userName: user.name)
            }
            
            // Start Weather Updates
            updateWeather()
            weatherTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                updateWeather()
            }
            
            // Animate markers after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    markersLoaded = true
                }
            }
        }
        .onDisappear {
            convoyManager.stopListening()
            weatherTimer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SevereWeatherAlert"))) { notification in
            if let userInfo = notification.userInfo {
                self.severeWeatherInfo = userInfo as? [String: Any]
                withAnimation { self.showWeatherAlert = true }
            }
        }
        .sheet(isPresented: $showAddSpotSheet) {
            AddSpotView(coordinate: currentCenter)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSpotDetailSheet) {
            if let spot = selectedSpot {
                SpotDetailView(spot: spot)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("لا يمكنك إضافة مكان هنا", isPresented: $showLocationError) {
            Button("حسناً", role: .cancel) { }
        } message: {
            Text("يجب أن تكون في نفس المنطقة لإضافة مكان جديد. (المسافة المسموحة 50 كم)")
        }
    }
    
    @ViewBuilder
    private var searchAndFilterOverlay: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("ابحث عن مكان...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Category Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "All" chip
                    FilterChip(
                        title: "الكل",
                        icon: "square.grid.2x2.fill",
                        isSelected: selectedCategories.isEmpty && !showProOnly
                    ) {
                        selectedCategories.removeAll()
                        showProOnly = false
                    }
                    
                    // NEW: Convoy Toggle Chip
                    FilterChip(
                        title: "القافلة",
                        icon: "car.2.fill",
                        isSelected: showConvoyMembers
                    ) {
                        withAnimation { showConvoyMembers.toggle() }
                    }
                    
                    // NEW: Pro/Exclusive Chip
                    FilterChip(
                        title: "💎 مميز",
                        icon: "crown.fill",
                        isSelected: showProOnly
                    ) {
                        showProOnly.toggle()
                        if showProOnly { selectedCategories.removeAll() }
                    }
                    
                    ForEach(availableCategories, id: \.self) { category in
                        FilterChip(
                            title: category,
                            icon: iconForCategory(category),
                            isSelected: selectedCategories.contains(category)
                        ) {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Spot Count Badge
            HStack {
                Text("\(filteredSpots.count) مكان")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: Capsule())
                
                if let weather = currentWeather {
                    WeatherCapsule(weather: weather)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Severe Weather Alert
            if showWeatherAlert, let info = severeWeatherInfo {
                WeatherAlertBanner(info: info) {
                    showWeatherAlert = false
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func ipadSidePanel(for spot: CampingSpot) -> some View {
        HStack {
            ZStack(alignment: .topTrailing) {
                SpotDetailView(spot: spot)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .frame(width: 400)
                    .shadow(color: .black.opacity(0.3), radius: 20)
                
                Button(action: { selectedSpot = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.white)
                        .shadow(radius: 5)
                        .padding()
                }
            }
            .padding()
            .transition(.move(edge: .leading))
            .zIndex(100)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var centerCrosshair: some View {
        Image(systemName: "plus")
            .font(.largeTitle)
            .foregroundStyle(Color.red)
            .shadow(radius: 2)
    }
    
    @ViewBuilder
    private var rightSideButtons: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation {
                        is3DMode.toggle()
                        position = .region(MKCoordinateRegion(
                            center: currentCenter,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }
                }) {
                    Image(systemName: is3DMode ? "view.2d" : "view.3d")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: Circle())
                }

                Menu {
                    ForEach(MapStyleOption.allCases, id: \.self) { style in
                        Button(action: { currentMapStyle = style }) {
                            Label(style.rawValue, systemImage: style.icon)
                        }
                    }
                } label: {
                    Image(systemName: currentMapStyle.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
            }
            .padding(.bottom, 160)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    @ViewBuilder
    private var bottomControls: some View {
        VStack {
            Spacer()
            HStack {
                if isAddMode {
                    Button(action: { isAddMode = false }) {
                        Text("إلغاء")
                            .fontWeight(.bold)
                            .padding()
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                    Button(action: validateAndAddSpot) {
                        Text("تأكيد الموقع 📍")
                            .fontWeight(.bold)
                            .padding()
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .foregroundStyle(Color.white)
                    }
                } else {
                    Spacer()
                    Button(action: { withAnimation { isAddMode = true } }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                            .frame(width: 60, height: 60)
                            .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 10)
                    }
                }
            }
            .padding(.bottom, isAddMode ? 40 : 100)
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var iphoneDetailCard: some View {
        VStack {
            Spacer()
            if let spot = selectedSpot {
                VStack(spacing: 0) {
                    GlassSpotCard(spot: spot)
                        .onTapGesture { showSpotDetailSheet = true }
                    
                    HStack {
                        QuickActionButton(icon: "arrow.triangle.turn.up.right.fill", label: "اتجاهات") {
                            openMap(app: .apple, for: spot)
                        }
                        QuickActionButton(icon: "square.and.arrow.up", label: "مشاركة") { }
                        Spacer()
                        Text(spot.type)
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.3))
                    .clipShape(bottomCorners: 16)
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .id(spot.id)
                .padding(.bottom, 60)
            }
        }
    }
    
    @MapContentBuilder
    private var mapContent: some MapContent {
        UserAnnotation()
        
        // Spot Markers
        ForEach(filteredSpots) { spot in
            Annotation(spot.name, coordinate: spot.coordinate) {
                SpotMarkerView(
                    spot: spot,
                    isSelected: selectedSpot?.id == spot.id,
                    isLoaded: markersLoaded
                )
                .environmentObject(store)
            }
            .tag(spot)
        }
        
        // Convoy Member Markers
        if showConvoyMembers {
            ForEach(convoyManager.members) { member in
                if let loc = member.lastLocation {
                    Annotation(member.name, coordinate: loc) {
                        ConvoyMemberMarker(member: member)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func centerOnUserLocation() {
        withAnimation {
            position = .userLocation(
                fallback: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                )
            )
            is3DMode = false
        }
    }
    
    func updateWeather() {
        Task {
            let weather = await WeatherManager.shared.getWeather(
                latitude: currentCenter.latitude,
                longitude: currentCenter.longitude
            )
            DispatchQueue.main.async {
                self.currentWeather = weather
            }
        }
    }
    
    func iconForCategory(_ type: String) -> String {
        switch type.lowercased() {
        case "camping", "مخيم", "مخيمات": return "tent.fill"
        case "hiking", "مشي", "تسلق": return "figure.hiking"
        case "fishing", "صيد", "صيد سمك": return "fish.fill"
        case "valley", "وادي", "أودية": return "water.waves"
        case "mountain", "جبل", "جبال": return "mountain.2.fill"
        case "desert", "كثبان", "صحراء", "رمال": return "sun.dust.fill"
        case "روضة", "روضات": return "leaf.fill"
        case "شاطئ", "بحر": return "beach.umbrella.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    func validateAndAddSpot() {
        guard let userLoc = locationManager.location else {
            print("User location unknown")
            return
        }
        
        let mapCenter = currentCenter
        let centerLoc = CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
        let distance = userLoc.distance(from: centerLoc)
        
        if distance < 50000 {
            showAddSpotSheet = true
            isAddMode = false
        } else {
            showLocationError = true
        }
    }

    enum PreferredMapApp { case apple, google, waze }
    
    func openMap(app: PreferredMapApp, for spot: CampingSpot) {
        let lat = spot.coordinate.latitude
        let long = spot.coordinate.longitude
        let urlString: String
        
        switch app {
        case .apple: urlString = "maps://?daddr=\(lat),\(long)"
        case .google: urlString = "comgooglemaps://?daddr=\(lat),\(long)"
        case .waze: urlString = "waze://?ll=\(lat),\(long)&navigate=yes"
        }
        
        if let url = URL(string: urlString) { UIApplication.shared.open(url) }
    }
}

// MARK: - Spot Marker View

struct SpotMarkerView: View {
    let spot: CampingSpot
    let isSelected: Bool
    let isLoaded: Bool
    @EnvironmentObject var store: AppDataStore
    
    var isLocked: Bool {
        spot.isProOnly && !(store.userProfile?.isPro ?? false)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: isLocked ? "lock.fill" : iconForCategory(spot.type))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(
                    Circle()
                        .fill(isLocked ? Color.yellow.gradient : colorForCategory(spot.type).gradient)
                        .shadow(color: (isLocked ? Color.yellow : colorForCategory(spot.type)).opacity(0.5), radius: isSelected ? 8 : 4)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
                .animation(.easeOut(duration: 0.4), value: isLoaded)
                .overlay(alignment: .topTrailing) {
                    if OfflineMapManager.shared.isDownloaded(spot.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.green)
                            .background(Circle().fill(.white))
                            .offset(x: 4, y: -4)
                    }
                }
        }
    }
    
    func iconForCategory(_ type: String) -> String {
        switch type.lowercased() {
        case "camping", "مخيم", "مخيمات": return "tent.fill"
        case "hiking", "مشي", "تسلق": return "figure.hiking"
        case "fishing", "صيد", "صيد سمك": return "fish.fill"
        case "valley", "وادي", "أودية": return "water.waves"
        case "mountain", "جبل", "جبال": return "mountain.2.fill"
        case "desert", "كثبان", "صحراء", "رمال": return "sun.dust.fill"
        case "روضة", "روضات": return "leaf.fill"
        case "شاطئ", "بحر": return "beach.umbrella.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    func colorForCategory(_ type: String) -> Color {
        switch type.lowercased() {
        case "camping", "مخيم", "مخيمات": return .orange
        case "hiking", "مشي", "تسلق": return .green
        case "fishing", "صيد", "صيد سمك": return .blue
        case "valley", "وادي", "أودية": return .cyan
        case "mountain", "جبل", "جبال": return .brown
        case "desert", "كثبان", "صحراء", "رمال": return .yellow
        case "روضة", "روضات": return .mint
        case "شاطئ", "بحر": return .teal
        default: return .red
        }
    }
}

// MARK: - Filter Chip View

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(isSelected ? .regular : .regular.interactive(), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    KashatMap()
        .environmentObject(AppDataStore())
        .environmentObject(SettingsManager())
}

// MARK: - New Map UI Components

struct ConvoyMemberMarker: View {
    let member: ConvoyMember
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "car.side.fill")
                .font(.caption2)
                .padding(8)
                .background(Circle().fill(.blue.gradient))
                .foregroundStyle(.white)
            Text(member.name)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
        }
    }
}

struct WeatherCapsule: View {
    let weather: Weather
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: weather.currentWeather.symbolName)
                .foregroundStyle(.yellow)
            Text("\(Int(weather.currentWeather.temperature.converted(to: .celsius).value))°")
                .fontWeight(.bold)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: Capsule())
    }
}

struct WeatherAlertBanner: View {
    let info: [String: Any]
    let onDismiss: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading) {
                Text("تنبيه جوي!")
                    .font(.caption.bold())
                Text("رياح شديدة (\(info["speed"] ?? 0) كم/س) في هذه المنطقة.")
                    .font(.system(size: 10))
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.2), lineWidth: 1))
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .foregroundStyle(.white)
    }
}

extension View {
    func clipShape(bottomCorners radius: CGFloat) -> some View {
        self.clipShape(RoundedCorner(radius: radius, corners: [.bottomLeft, .bottomRight]))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
