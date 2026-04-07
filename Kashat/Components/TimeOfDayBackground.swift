//
//  TimeOfDayBackground.swift
//  Kashat
//

import SwiftUI

struct TimeOfDayBackground: View {
    let hour: Int
    
    // Calculates what phase of the day it is roughly
    var colors: [Color] {
        switch hour {
        case 0..<5:
            // Deep Night
            return [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")]
        case 5..<8:
            // Sunrise
            return [Color(hex: "FF5e62"), Color(hex: "FF9966")]
        case 8..<16:
            // Day
            return [Color(hex: "1CB5E0"), Color(hex: "000046")]
        case 16..<19:
            // Sunset
            return [Color(hex: "F2709C"), Color(hex: "FF9472")]
        case 19..<24:
            // Evening / Night
            return [Color(hex: "141E30"), Color(hex: "243B55")]
        default:
            return [.blue, .black]
        }
    }
    
    var isNight: Bool { hour >= 19 || hour < 6 }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Night star field
            if isNight {
                StarfieldView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // Subtle glass overlay to blend with Liquid Glass design language
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(isNight ? 0.5 : 0.25)
                .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 3.0), value: hour)
    }
}

// MARK: - Animated Starfield (Canvas based - battery friendly)
struct StarfieldView: View {
    // Pre-generate stable star positions using a seed
    private let stars: [(x: Double, y: Double, radius: Double, seed: Double)] = (0..<120).map { i in
        let pseudoX = Double((i * 7919 + 31337) % 1000) / 1000.0
        let pseudoY = Double((i * 6271 + 42101) % 1000) / 1000.0
        let pseudoR = Double((i * 9973) % 5 + 1) / 3.0
        let seed    = Double(i) * 0.37
        return (x: pseudoX, y: pseudoY, radius: pseudoR, seed: seed)
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for star in stars {
                    // Gentle twinkle using a sine wave per star
                    let twinkle = (sin(now * 0.8 + star.seed) + 1) / 2  // 0..1
                    let opacity = 0.3 + twinkle * 0.7
                    
                    let cx = star.x * size.width
                    let cy = star.y * size.height * 0.65 // Cluster stars in top 65% (sky)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: cx - star.radius, y: cy - star.radius,
                                               width: star.radius * 2, height: star.radius * 2)),
                        with: .color(.white.opacity(opacity))
                    )
                    
                    // Rare larger stars get a soft glow halo
                    if star.radius > 1.2 {
                        context.fill(
                            Path(ellipseIn: CGRect(x: cx - star.radius * 3, y: cy - star.radius * 3,
                                                   width: star.radius * 6, height: star.radius * 6)),
                            with: .color(.white.opacity(opacity * 0.15))
                        )
                    }
                }
            }
        }
    }
}
