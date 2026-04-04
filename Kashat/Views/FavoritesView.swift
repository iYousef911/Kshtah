//
//  FavoritesView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//


import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0 // 0 = Spots, 1 = Gear
    
    var savedSpots: [CampingSpot] {
        store.spots.filter { store.isSpotFavorite($0) }
    }
    
    var savedGear: [GearItem] {
        store.gear.filter { store.isGearFavorite($0) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                VStack(spacing: 20) {
                    // Segment Control
                    HStack {
                        SegmentButton(title: "أماكن (\(savedSpots.count))", isSelected: selectedTab == 0) { selectedTab = 0 }
                        SegmentButton(title: "معدات (\(savedGear.count))", isSelected: selectedTab == 1) { selectedTab = 1 }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.capsule)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    ScrollView {
                        if selectedTab == 0 {
                            // Spots List
                            if savedSpots.isEmpty {
                                EmptyStateView(message: "ما حفظت أماكن لسا!")
                                    .padding(.horizontal)
                            } else {
                                GlassEffectContainer {
                                    VStack(spacing: 15) {
                                        ForEach(savedSpots) { spot in
                                            // Use existing GlassSpotCard
                                            GlassSpotCard(spot: spot)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        } else {
                            // Gear Grid
                            if savedGear.isEmpty {
                                EmptyStateView(message: "ما حفظت معدات لسا!")
                                    .padding(.horizontal)
                            } else {
                                GlassEffectContainer {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                        ForEach(savedGear) { item in
                                            GearCard(item: item)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("المفضلة")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("رجوع") { dismiss() }.foregroundStyle(Color.white)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let message: String
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 15) {
                Image(systemName: "heart.slash")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.white)
                    .shadow(radius: 5)
                Text(message)
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 250)
        }
    }
}

#Preview {
    FavoritesView()
}
