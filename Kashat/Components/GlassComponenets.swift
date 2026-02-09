//
//  GlassComponenets.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
internal import Combine

// MARK: - Liquid Background View (Theme Engine)
struct LiquidBackgroundView: View {
    @EnvironmentObject var theme: ThemeManager
    var color: Color? = nil // NEW: Support for custom override (e.g., Onboarding)
    
    @State private var time: Float = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    private var animatedMeshPoints: [SIMD2<Float>] {
        let timeDouble = Double(time)
        let centerX = 0.5 + Float(sin(timeDouble) * 0.1)
        let centerY = 0.5 + Float(cos(timeDouble) * 0.1)
        
        return [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(centerX, centerY), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ]
    }
    
    var themeColors: [Color] {
        if let overrideColor = color {
            return [
                overrideColor, overrideColor.opacity(0.8), overrideColor,
                overrideColor.opacity(0.4), .black, overrideColor.opacity(0.4),
                overrideColor, overrideColor.opacity(0.8), overrideColor
            ]
        }
        
        let base = theme.currentTheme.gradientColors
        if theme.currentTheme == .foundingDay {
            return [
                base[0], base[1], base[0],
                base[2].opacity(0.15), base[0].opacity(0.3), base[2].opacity(0.15),
                base[1].opacity(0.8), base[0], base[1].opacity(0.8)
            ]
        } else {
            return [
                base[0], base[1], base[0],
                Color(red: 0.25, green: 0.2, blue: 0.1).opacity(0.4),
                Color(red: 0.05, green: 0.15, blue: 0.2).opacity(0.3),
                Color(red: 0.25, green: 0.2, blue: 0.1).opacity(0.4),
                base[0], base[1], base[0]
            ]
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animatedMeshPoints,
                    colors: themeColors
                )
                .ignoresSafeArea()
                .onReceive(timer) { _ in time += 0.05 }
            } else {
                // Fallback for older iOS
                LinearGradient(colors: [themeColors[0], .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Glass Modifiers & Styles
extension View {
    @ViewBuilder
    func glassEffect(_ style: GlassStyle = .regular, in shape: some Shape) -> some View {
        if #available(iOS 18.0, *) {
            self.background(
                shape.fill(.ultraThinMaterial)
                    // Updated Shadows to be more subtle/clean
                    .shadow(color: .white.opacity(0.05), radius: 1, x: -1, y: -1)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 4, y: 4)
            )
            .background(style.tintColor.map { shape.fill($0) })
            .clipShape(shape)
        } else {
            self.background(.ultraThinMaterial).clipShape(shape)
        }
    }
}

struct GlassStyle {
    var tintColor: Color? = nil
    static let regular = GlassStyle()
    func interactive() -> GlassStyle { return self }
    func tint(_ color: Color) -> GlassStyle {
        var copy = self
        copy.tintColor = color
        return copy
    }
}

struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    var body: some View { content }
}

// MARK: - Reusable Components
struct GlassSpotCard: View {
    let spot: CampingSpot
    @EnvironmentObject var store: AppDataStore
    
    var isFavorite: Bool { store.isSpotFavorite(spot) }
    
    // NEW: Visual Locking Logic
    var isLocked: Bool {
        spot.isProOnly && !(store.userProfile?.isPro ?? false)
    }
    
    var body: some View {
        HStack {
            ZStack {
                if let url = spot.imageURL, let validURL = URL(string: url) {
                    AsyncImage(url: validURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .blur(radius: isLocked ? 6 : 0) // Blur if locked
                } else {
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)).frame(width: 80, height: 80)
                    Image(systemName: "photo").foregroundStyle(Color.white.opacity(0.5))
                }
                
                // Lock Overlay
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    // Hide Name if Locked
                    Text(isLocked ? "موقع حصري 💎" : spot.name)
                        .font(.headline)
                        .foregroundStyle(isLocked ? Color.yellow : Color.white)
                    
                    if spot.isProOnly && !isLocked {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                
                // Hide Location if Locked
                Text(isLocked ? "متاح فقط لمشتركي PRO" : spot.location)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
                
                HStack {
                    Image(systemName: "star.fill").foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.4)).font(.caption2)
                    Text(String(format: "%.1f", spot.rating)).font(.caption2.weight(.bold)).foregroundStyle(Color.white)
                }
            }
            Spacer()
            
            Button(action: { withAnimation(.spring) { store.toggleFavoriteSpot(spot) } }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(isFavorite ? Color(red: 0.8, green: 0.3, blue: 0.3) : Color.white.opacity(0.3))
                    .symbolEffect(.bounce, value: isFavorite)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassEffect(GlassStyle.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
        // Add a gold border for locked/pro spots to make them pop even more
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isLocked ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
// MARK: - Liquid Glass Card (New)
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    @State private var time: Float = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 1. Dynamic Liquid Background
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.5 + Float(sin(Double(time)) * 0.1), 0.5 + Float(cos(Double(time)) * 0.1)), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                    ],
                    colors: [
                        .orange, .red, .purple,
                        .blue.opacity(0.5), .white.opacity(0.8), .orange.opacity(0.5),
                        .purple, .red, .orange
                    ]
                )
                .onReceive(timer) { _ in time += 0.05 }
            } else {
                LinearGradient(colors: [.orange, .red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            
            // 2. Ultra Thin Glass Layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85) // High transparency for "Liquid" look
            
            // 3. Content
            content
                .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1), .white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 10)
    }
}
