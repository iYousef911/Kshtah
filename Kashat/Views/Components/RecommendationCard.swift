//
//  RecommendationCard.swift
//  Kashat
//
//  Created by AI Assistant on 22/11/2025.
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: RecommendedSpot
    @EnvironmentObject var settings: SettingsManager
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    
    // Apple Intelligence / Siri Colors (Pink, Purple, Cyan, Orange)
    let siriColors: [Color] = [
        Color(hue: 0.8, saturation: 0.8, brightness: 1.0), // Purple
        Color(hue: 0.9, saturation: 0.8, brightness: 1.0), // Pink
        Color(hue: 0.55, saturation: 0.8, brightness: 1.0), // Cyan/Blue
        Color(hue: 0.05, saturation: 0.8, brightness: 1.0), // Orange
        Color(hue: 0.8, saturation: 0.8, brightness: 1.0)  // Loop back
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: recommendation.spot.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 250, height: 320)
            .clipped()
            .blur(radius: recommendation.spot.isProOnly ? 5 : 0) // Blur for Pro exclusive
            .overlay {
                if recommendation.spot.isProOnly {
                    ZStack {
                        Color.black.opacity(0.4)
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.title)
                            Text(settings.t("حصري لـ PRO"))
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            
            // Gradient Overlay
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Weather Badge
                HStack(spacing: 6) {
                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.multicolor)
                    Text(recommendation.tempString)
                        .font(.caption.bold())
                    Text("•")
                    Text(settings.t("طقس ممتاز"))
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                Spacer()
                
                // Spot Info
                Text(recommendation.spot.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                // NEW: Smart Insight Text
                Text(recommendation.smartInsight)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .padding(.bottom, 2)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(recommendation.spot.location)
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                
                // Score Badge
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text(settings.t("نسبة الملاءمة") + ": \(Int(recommendation.weatherScore))%")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .frame(width: 250, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        // Enhanced Siri Glow (Inner + Outer)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    AngularGradient(gradient: Gradient(colors: siriColors), center: .center, startAngle: .degrees(rotation), endAngle: .degrees(rotation + 360)),
                    lineWidth: 4
                )
                .blur(radius: 2) // Soften the edge
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AngularGradient(gradient: Gradient(colors: siriColors), center: .center, startAngle: .degrees(rotation), endAngle: .degrees(rotation + 360)))
                .blur(radius: 15) // Outer ambient glow
                .opacity(0.6)
        )
        .scaleEffect(pulse)
        .onAppear {
            // Rotation Animation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // Subtle Breathing Animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = 1.02
            }
        }
    }
}
