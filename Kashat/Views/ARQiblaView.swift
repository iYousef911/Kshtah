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
    @State private var isARMode = false
    
    var body: some View {
        ZStack {
            // Show AR or Compass based on mode
            if isARMode && isARKitSupported() {
                // AR Camera View
                ARQiblaARView(compass: compass)
                    .ignoresSafeArea()
            } else {
                // Original Compass View
                compassView
            }
            
            // Overlay Controls (always visible)
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.white.opacity(0.8))
                            .shadow(radius: 5)
                    }
                    Spacer()
                    Text("تحديد القبلة")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .shadow(radius: 5)
                    Spacer()
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color.green)
                        .shadow(radius: 5)
                }
                .padding()
                
                // Mode Picker (only show if AR is supported)
                if isARKitSupported() {
                    Picker("الوضع", selection: $isARMode) {
                        Text("البوصلة").tag(false)
                        Text("الواقع المعزز").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Info Card
                VStack(spacing: 8) {
                    Text(isARMode ? "وجّه الكاميرا للعثور على القبلة" : "اتجه نحو الرمز الذهبي")
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
    
    // MARK: - Compass View (Original)
    private var compassView: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
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
            .rotationEffect(.degrees(-compass.heading))
            .animation(.easeOut(duration: 0.3), value: compass.heading)
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
