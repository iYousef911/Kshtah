//
//  ARQiblaView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import SwiftUI

struct ARQiblaView: View {
    @StateObject private var compass = CompassManager()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 1. Camera Background Simulation (Dark Gradient for vibe)
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 2. Compass UI
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    Spacer()
                    Text("تحديد القبلة")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Image(systemName: "location.fill") // GPS Status
                        .foregroundStyle(Color.green)
                }
                .padding()
                
                Spacer()
                
                // The Rotating Compass
                ZStack {
                    // Outer Ring
                    Circle()
                        .stroke(LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        .frame(width: 300, height: 300)
                        .glassEffect(GlassStyle.regular, in: Circle())
                    
                    // Degree Marks
                    ForEach(0..<72) { i in
                        Rectangle()
                            .fill(Color.white.opacity(i % 9 == 0 ? 0.8 : 0.2))
                            .frame(width: 2, height: i % 9 == 0 ? 15 : 8)
                            .offset(y: -135)
                            .rotationEffect(.degrees(Double(i) * 5))
                    }
                    
                    // North Indicator
                    VStack {
                        Text("N")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.red)
                            .padding(.bottom, 240)
                    }
                    
                    // Qibla Indicator (Kaaba Icon)
                    VStack {
                        // FIX: Changed "kaaba" to "cube.fill" (SF Symbol)
                        Image(systemName: "cube.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.gold)
                            .offset(y: -110)
                    }
                    .rotationEffect(.degrees(compass.qiblaDirection))
                    
                    // Center Pivot
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                }
                .rotationEffect(.degrees(compass.heading)) // Rotate the whole dial based on device heading
                .animation(.easeOut(duration: 0.2), value: compass.heading)
                
                Spacer()
                
                // Info Card
                VStack(spacing: 8) {
                    Text("اتجه نحو الرمز الذهبي")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                    
                    Text("مكة المكرمة")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding()
                .glassEffect(GlassStyle.regular, in: Capsule())
                .padding(.bottom, 50)
            }
        }
    }
}

// Helper Color
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    ARQiblaView()
}
