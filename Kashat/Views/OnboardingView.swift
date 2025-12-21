//
//  OnboardingView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(image: "map.circle.fill", title: "اكتشف أماكن جديدة", description: "استكشف أفضل الكشتات والروضات المخفية في جميع أنحاء المملكة."),
        OnboardingPage(image: "tent.2.circle.fill", title: "تأجير مستلزمات البر", description: "ناقصك خيمة؟ ماطور؟ استأجر معدات التخييم من جيرانك بسهولة."),
        OnboardingPage(image: "person.3.sequence.fill", title: "مجتمع الكشاتة", description: "تواصل مع أهل البر، شارك تجاربك، وكون صداقات جديدة.")
    ]
    
    var body: some View {
        ZStack {
            // Background
            LiquidBackgroundView()
            
            VStack {
                // Skip Button
                HStack {
                    if currentPage < pages.count - 1 {
                        Button("تخطي") {
                            withAnimation { hasSeenOnboarding = true }
                        }
                        .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .padding(.top, 40)
                
                // Swipable Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].image)
                                .font(.system(size: 120))
                                .foregroundStyle(Color.white.gradient)
                                .shadow(color: Color.blue.opacity(0.5), radius: 30)
                                .padding(.bottom, 30)
                            
                            Text(pages[index].title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                            
                            Text(pages[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.white.opacity(0.7))
                                .padding(.horizontal, 30)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Custom dots below
                .frame(height: 400)
                
                Spacer()
                
                // Custom Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring, value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Next / Start Button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        withAnimation { hasSeenOnboarding = true }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "ابدأ الآن" : "التالي")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .transition(.opacity)
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}
#Preview {
    OnboardingView(hasSeenOnboarding: false)
}
