//
//  SplashView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 28/11/2025.
//


import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            // Background (Updated Dark Theme)
            LiquidBackgroundView()
            
            VStack(spacing: 20) {
                // Logo Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 150, height: 150)
                        .glassEffect(GlassStyle.regular, in: Circle())
                        // Add a subtle Gold Border
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.8, green: 0.7, blue: 0.4).opacity(0.6), // Gold
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: "tent.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            // Premium Gold Gradient for Logo
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.85, blue: 0.6), // Light Gold
                                    Color(red: 0.7, green: 0.5, blue: 0.2)    // Dark Bronze
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.2).opacity(0.3), radius: 20)
                }
                .scaleEffect(size)
                .opacity(opacity)
                
                // Text Brand
                Text("كشتات")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text("رفيقك في البر")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                self.isAnimating = true
                self.size = 1.0
                self.opacity = 1.0
            }
        }
    }
}
#Preview {
    SplashView()
}
