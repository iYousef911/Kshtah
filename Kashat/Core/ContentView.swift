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
    
    // App Lock Logic
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @State private var isLocked = true
    @StateObject private var biometricManager = BiometricManager.shared
    
    var body: some View {
        Group {
            if firebase.user != nil {
                // LOGGED IN: Show Main App
                ZStack {
                    LiquidBackgroundView()
                    
                    TabView(selection: $selectedTab) {
                        HomeFeedView().tabItem { Label(settings.t("الرئيسية"), systemImage: "house.fill") }.tag(0)
                        MessagesView().tabItem { Label(settings.t("الرسائل"), systemImage: "bubble.left.and.bubble.right.fill") }.tag(1)
                        KashatMap().tabItem { Label(settings.t("الخريطة"), systemImage: "map.fill") }.tag(2)
                        ProfileView().tabItem { Label(settings.t("حسابي"), systemImage: "person.fill") }.tag(3)
                    }
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                    .tint(Color.white)
                    .id(settings.language) // Force Rebuild on Language Change
                }
                .preferredColorScheme(.dark)
            } else {
                // LOGGED OUT: Show Login
                LoginView()
            }
        }
        .overlay {
            if isAppLockEnabled && isLocked {
                LockedView(unlockAction: unlockApp)
            }
        }
        .onAppear {
            if isAppLockEnabled {
                unlockApp()
            } else {
                isLocked = false
            }
            
            // NEW: Strategic Paywall on Launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !SubscriptionManager.shared.isPro {
                    SubscriptionManager.shared.presentPaywall()
                }
            }
        }
    }
    
    func unlockApp() {
        biometricManager.authenticateUser { success in
            if success {
                withAnimation { isLocked = false }
            }
        }
    }
}

// MARK: - Locked View
struct LockedView: View {
    var unlockAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                
                Text("التطبيق مقفل")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Button(action: unlockAction) {
                    Label("فتح القفل", systemImage: "faceid")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDataStore())
        .environmentObject(SettingsManager())
}
