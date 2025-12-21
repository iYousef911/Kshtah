//
//  AppIconView.swift
//  Kashat
//
//  Created by Assistant on 22/11/2025.
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.8, green: 0.4, blue: 0.0), // Warm Orange/Sunset
                    Color(red: 0.1, green: 0.3, blue: 0.1)  // Deep Forest Green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glassmorphism Overlay (Subtle)
            LinearGradient(
                colors: [.white.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Tent Icon
            Image(systemName: "tent.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 500) // Adjust relative to 1024 size
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .frame(width: 1024, height: 1024) // App Store Icon Size
        .clipShape(RoundedRectangle(cornerRadius: 0)) // Keep square for export
        .ignoresSafeArea()
    }
}

#Preview {
    AppIconView()
        .frame(width: 300, height: 300)
}
