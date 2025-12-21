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
    
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animatedMeshPoints,
                    colors: [
                        // Row 1: Deep Night Sky (Top)
                        .black, Color(red: 0.05, green: 0.08, blue: 0.12), .black,
                        
                        // Row 2: The "Liquid" Flow - Subtle Gold & Dark Teal
                        // Professional Palette: Bronze/Gold mixed with Deep Teal
                        Color(red: 0.25, green: 0.2, blue: 0.1).opacity(0.4), // Subtle Gold/Sand
                        Color(red: 0.05, green: 0.15, blue: 0.2).opacity(0.3), // Deep Teal
                        Color(red: 0.25, green: 0.2, blue: 0.1).opacity(0.4), // Subtle Gold/Sand
                        
                        // Row 3: Deep Ground (Bottom)
                        .black, Color(red: 0.05, green: 0.05, blue: 0.08), .black
                    ]
                )
                .ignoresSafeArea()
                .onReceive(timer) { _ in time += 0.05 }
            } else {
                Color.black.ignoresSafeArea()
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
                } else {
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)).frame(width: 80, height: 80)
                    Image(systemName: "photo").foregroundStyle(Color.white.opacity(0.5))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name).font(.headline).foregroundStyle(Color.white)
                Text(spot.location).font(.caption).foregroundStyle(Color.white.opacity(0.6))
                HStack {
                    // Update Star color to match new Gold theme
                    Image(systemName: "star.fill").foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.4)).font(.caption2)
                    Text(String(format: "%.1f", spot.rating)).font(.caption2.weight(.bold)).foregroundStyle(Color.white)
                }
            }
            Spacer()
            
            Button(action: { withAnimation(.spring) { store.toggleFavoriteSpot(spot) } }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(isFavorite ? Color(red: 0.8, green: 0.3, blue: 0.3) : Color.white.opacity(0.3)) // Muted Red
                    .symbolEffect(.bounce, value: isFavorite)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassEffect(GlassStyle.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
    }
}
