//
//  KashatMap.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import MapKit

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
    
    // NEW: Map Style
    @State private var currentMapStyle: MapStyleOption = .hybrid
    @State private var showMapStylePicker = false
    
    // NEW: Animation
    @State private var markersLoaded = false
    
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
            return matchesSearch && matchesCategory
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
                UserAnnotation()
                
                ForEach(filteredSpots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        SpotMarkerView(
                            spot: spot,
                            isSelected: selectedSpot?.id == spot.id,
                            isLoaded: markersLoaded
                        )
                    }
                    .tag(spot)
                }
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
            
            // NEW: Search & Filter Overlay
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
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Category Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" chip
                        FilterChip(
                            title: "الكل",
                            icon: "square.grid.2x2.fill",
                            isSelected: selectedCategories.isEmpty
                        ) {
                            selectedCategories.removeAll()
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
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            
            // iPad Side Panel
            if sizeClass == .regular, let spot = selectedSpot {
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

            // Center Crosshair (Only in Add Mode)
            if isAddMode {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .foregroundStyle(Color.red)
                    .shadow(radius: 2)
            }
            
            // Right Side Buttons (My Location + Map Style)
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Map Style Button
                    Button(action: { showMapStylePicker.toggle() }) {
                        Image(systemName: currentMapStyle.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                    
                    // My Location Button
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                }
                .padding(.bottom, 180)
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Bottom Controls
            VStack {
                Spacer()
                HStack {
                    if isAddMode {
                        Button(action: { isAddMode = false }) {
                            Text("إلغاء")
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Button(action: validateAndAddSpot) {
                            Text("تأكيد الموقع 📍")
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                    } else {
                        Spacer()
                        Button(action: {
                            withAnimation { isAddMode = true }
                        }) {
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
            
            // Detail Card (Only if NOT in Add Mode, iPhone only)
            if !isAddMode && sizeClass == .compact {
                VStack {
                    Spacer()
                    if let spot = selectedSpot {
                        GlassSpotCard(spot: spot)
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id(spot.id)
                            .onTapGesture {
                                showSpotDetailSheet = true
                            }
                            .padding(.bottom, 60)
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            // Animate markers after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    markersLoaded = true
                }
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
        // Map Style Picker
        .confirmationDialog("نوع الخريطة", isPresented: $showMapStylePicker) {
            ForEach(MapStyleOption.allCases, id: \.self) { style in
                Button(style.rawValue) {
                    withAnimation { currentMapStyle = style }
                }
            }
        }
        .alert("لا يمكنك إضافة مكان هنا", isPresented: $showLocationError) {
            Button("حسناً", role: .cancel) { }
        } message: {
            Text("يجب أن تكون في نفس المنطقة لإضافة مكان جديد. (المسافة المسموحة 50 كم)")
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
}

// MARK: - Spot Marker View

struct SpotMarkerView: View {
    let spot: CampingSpot
    let isSelected: Bool
    let isLoaded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: iconForCategory(spot.type))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(
                    Circle()
                        .fill(colorForCategory(spot.type).gradient)
                        .shadow(color: colorForCategory(spot.type).opacity(0.5), radius: isSelected ? 8 : 4)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.3 : (isLoaded ? 1.0 : 0.5))
                .opacity(isLoaded ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                .animation(.easeOut(duration: 0.4), value: isLoaded)
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
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    KashatMap()
}
