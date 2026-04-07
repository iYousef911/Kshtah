//
//  WeatherParticleOverlay.swift
//  Kashat
//

import SwiftUI

enum WeatherCondition {
    case clear, rain, snow, dust, fog
}

struct WeatherParticleOverlay: View {
    let condition: WeatherCondition
    
    var body: some View {
        Group {
            switch condition {
            case .rain:
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for i in 0..<100 {
                            let randomX = Double(i * 10 % Int(size.width))
                            // Stagger drop timing based on index
                            let yOffset = now * Double(500 + (i % 50) * 10) + Double(i * 20)
                            let currentY = CGFloat(yOffset.truncatingRemainder(dividingBy: Double(size.height)))
                            
                            var path = Path()
                            path.move(to: CGPoint(x: randomX, y: currentY))
                            path.addLine(to: CGPoint(x: randomX - 5, y: currentY + 30))
                            
                            context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 1.5)
                        }
                    }
                }
            case .snow:
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for i in 0..<80 {
                            let wave = sin(now * Double(i) * 0.1) * 20
                            let randomX = Double(i * 15 % Int(size.width)) + wave
                            
                            let yOffset = now * Double(50 + (i % 20) * 5) + Double(i * 40)
                            let currentY = CGFloat(yOffset.truncatingRemainder(dividingBy: Double(size.height)))
                            
                            context.fill(Path(ellipseIn: CGRect(x: randomX, y: currentY, width: 4, height: 4)), with: .color(.white.opacity(0.8)))
                        }
                    }
                }
            case .dust:
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for i in 0..<150 {
                            let speedFactor = Double(i % 10 + 10)
                            let xOffset = now * speedFactor + Double(i * 30) // Drift left to right usually
                            let currentX = CGFloat(xOffset.truncatingRemainder(dividingBy: Double(size.width)))
                            
                            let wave = cos(now * 0.5 + Double(i)) * Double(i % 20)
                            let yBase = Double(size.height) - Double(i * 3 % Int(size.height * 0.6)) // concentrate near bottom/middle
                            let currentY = CGFloat(yBase + wave)
                            
                            context.fill(Path(ellipseIn: CGRect(x: currentX, y: currentY, width: 3, height: 3)), with: .color(.orange.opacity(0.3)))
                        }
                    }
                }
            case .fog, .clear:
                EmptyView() // Liquid Glass already acts as fog mostly, clear does nothing
            }
        }
        .allowsHitTesting(false) // Never block touches
    }
}
