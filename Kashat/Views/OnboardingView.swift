//
//  OnboardingView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var showPermissions = false
    
    // Enhanced Pages
    let pages = [
        OnboardingPage(
            image: "tent.fill",
            title: "حياك في كشتة",
            description: "عالمك الأول للبر.. اكتشف، خيم، واستمتع بأجواء الصحراء.",
            color: .orange
        ),
        OnboardingPage(
            image: "map.fill",
            title: "اكتشف المجهول",
            description: "صادك ملل من نفس الأماكن؟ عندنا لك مئات الكشتات والروضات السرية.",
            color: .blue
        ),
        OnboardingPage(
            image: "camera.aperture",
            title: "عش اللحظة",
            description: "شارك صورك ولحظاتك الحية مع مجتمع الكشاتة وتفاعل معهم.",
            color: .purple
        ),
        OnboardingPage(
            image: "wand.and.stars",
            title: "ذكاء PRO",
            description: "خطط بذكاء مع AI: معرفة النجوم، تجهيز العزبة، وتوصيات الطقس.",
            color: .indigo
        ),
        OnboardingPage(
            image: "location.fill",
            title: "بداية الرحلة",
            description: "لأفضل تجربة، اسمح لنا بالوصول لموقعك وإرسال التنبيهات المهمة.",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            // Dynamic Background
            LiquidBackgroundView(color: pages[currentPage].color)
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack {
                // Header (Skip)
                HStack {
                    if currentPage < pages.count - 1 {
                        Button("تخطي") {
                            withAnimation { hasSeenOnboarding = true }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding()
                .padding(.top, 50)
                
                Spacer()
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            // Icon with Pulse Effect
                            Image(systemName: pages[index].image)
                                .font(.system(size: 100))
                                .foregroundStyle(.white.gradient)
                                .symbolEffect(.bounce, value: currentPage == index)
                                .shadow(color: pages[index].color.opacity(0.6), radius: 40)
                                .padding(.bottom, 20)
                            
                            Text(pages[index].title)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text(pages[index].description)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 30)
                                .lineLimit(3)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 450)
                
                // Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring, value: currentPage)
                    }
                }
                .padding(.bottom, 40)
                
                // Action Button
                if currentPage == pages.count - 1 {
                    VStack(spacing: 16) {
                        Button(action: requestPermissionsAndStart) {
                            Text("السماح وبدء الرحلة")
                                .fontWeight(.bold)
                                .foregroundStyle(pages[currentPage].color)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        
                        Button("ليس الآن") {
                            withAnimation { hasSeenOnboarding = true }
                        }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: {
                        withAnimation { currentPage += 1 }
                    }) {
                        Image(systemName: "arrow.left") // Arabic RTL: Arrow Left points forward visually usually, checking layout
                            .font(.title2.bold())
                            .foregroundStyle(pages[currentPage].color)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                
                Spacer().frame(height: 50)
            }
        }
        .environment(\.layoutDirection, .rightToLeft) // Ensure Arabic layout
    }
    
    // Permission Logic
    private func requestPermissionsAndStart() {
        // 1. Location
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        // 2. Notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("🔔 Notifications Granted: \(granted)")
        }
        
        // 3. Finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { hasSeenOnboarding = true }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsManager())
        .environmentObject(ThemeManager())
}
