//
//  MarketplaceView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI

struct MarketplaceView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager // NEW: Localization
    @State private var searchText = ""
    @State private var selectedCategory = "الكل"
    @State private var showAddGearSheet = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Filter Logic: Search Text + Category
    var filteredGear: [GearItem] {
        var items = store.gear
        
        // 1. Filter by Category
        if selectedCategory != "الكل" {
            items = items.filter { $0.category == selectedCategory }
        }
        
        // 2. Filter by Search
        if !searchText.isEmpty {
            items = items.filter { $0.name.contains(searchText) }
        }
        
        return items
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. Header & Search
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Color.white.opacity(0.6))
                                TextField(settings.t("ابحث عن خيمة، ماطور، حطب..."), text: $searchText)
                                    .foregroundStyle(Color.white)
                            }
                            .padding()
                            .glassEffect(GlassStyle.regular, in: Capsule())
                            
                            // Add Gear Button
                            Button(action: { showAddGearSheet = true }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.white)
                                    .padding(12)
                                    .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // 2. Categories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["الكل", "خيام", "كهرباء", "طبخ", "شواء", "انقاذ", "أخرى"], id: \.self) { cat in
                                    Button(action: { withAnimation { selectedCategory = cat } }) {
                                        Text(settings.t(cat))
                                            .font(.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .glassEffect(
                                                selectedCategory == cat ? GlassStyle.regular.interactive().tint(Color.blue.opacity(0.3)) : GlassStyle.regular.interactive(),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(Color.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 3. Gear Grid
                        if filteredGear.isEmpty {
                            // Empty State
                            VStack(spacing: 15) {
                                Image(systemName: "cube.box")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.white.opacity(0.3))
                                Text(settings.t("لا توجد منتجات"))
                                    .font(.headline)
                                    .foregroundStyle(Color.white.opacity(0.5))
                                
                                Button(action: { store.fetchGear() }) {
                                    Label(settings.t("تحديث"), systemImage: "arrow.clockwise")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .frame(height: 300)
                        } else {
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(filteredGear) { item in
                                    NavigationLink(destination: ProductDetailView(item: item)) {
                                        GearCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 100) // Spacer for TabBar
                }
                .blur(radius: store.isMarketplaceEnabled ? 0 : 10) // NEW: Conditional Blur
                .allowsHitTesting(store.isMarketplaceEnabled) // NEW: Conditional Interaction
                .disabled(!store.isMarketplaceEnabled)
                
                // Coming Soon Overlay
                if !store.isMarketplaceEnabled { // NEW: Conditional Overlay
                    VStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .padding(.bottom, 10)
                        
                        Text(settings.t("قريبا ..."))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                        
                        Text(settings.t("نعمل على تجهيز سوق الكشتة لخدمتكم بشكل أفضل"))
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                }
            }
            .navigationTitle("سوق الكشتة")
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable {
                store.fetchGear()
            }
            .onAppear {
                if store.gear.isEmpty {
                    store.fetchGear()
                }
            }
            .sheet(isPresented: $showAddGearSheet) {
                AddGearView()
                    .presentationDetents([.large])
            }
        }
        .trackScreen(name: "Marketplace") // Analytic Screen
    }
}

// MARK: - Gear Card Component
struct GearCard: View {
    let item: GearItem
    @EnvironmentObject var store: AppDataStore
    
    var isFavorite: Bool {
        store.isGearFavorite(item)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Image Area
            ZStack(alignment: .topLeading) {
                // Check if imageName is a URL (starts with http) or SF Symbol
                if item.imageName.starts(with: "http"), let url = URL(string: item.imageName) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.white.opacity(0.1) // Placeholder
                        }
                    }
                    .frame(height: 120)
                    .clipped()
                } else {
                    // Fallback to SF Symbol
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 120)
                    Image(systemName: item.imageName) // e.g., "tent.2.fill"
                        .font(.system(size: 40))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                
                // Heart Icon Overlay
                Button(action: {
                    withAnimation(.spring) {
                        store.toggleFavoriteGear(item)
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? Color.red : Color.white.opacity(0.5))
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.callout)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundStyle(Color.white)
                
                HStack {
                    Text("\(item.pricePerDay) ﷼")
                        .foregroundStyle(Color.green)
                        .fontWeight(.bold)
                    Text("/ يوم")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    
                    Spacer()
                    
                    if item.rating > 0 {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", item.rating))
                            .font(.caption)
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .padding(8)
        .glassEffect(GlassStyle.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
    }
}


#Preview {
    MarketplaceView()
}
