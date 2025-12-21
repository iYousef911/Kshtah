//
//  ContentView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var firebase = FirebaseManager.shared // Observe Auth
    @EnvironmentObject var settings: SettingsManager // NEW: settings for localization
    @State private var selectedTab = 0
    
    var body: some View {
        if firebase.user != nil {
            // LOGGED IN: Show Main App
            ZStack {
                LiquidBackgroundView()
                
                TabView(selection: $selectedTab) {
                    HomeFeedView().tabItem { Label(settings.t("الرئيسية"), systemImage: "house.fill") }.tag(0)
                    MarketplaceView().tabItem { Label(settings.t("السوق"), systemImage: "bag.fill") }.tag(1)
                    KashatMap().tabItem { Label(settings.t("الخريطة"), systemImage: "map.fill") }.tag(2)
                    ProfileView().tabItem { Label(settings.t("حسابي"), systemImage: "person.fill") }.tag(3)
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .tint(Color.white)
            }
            .preferredColorScheme(.dark)
        } else {
            // LOGGED OUT: Show Login
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDataStore())
        .environmentObject(SettingsManager())
}
