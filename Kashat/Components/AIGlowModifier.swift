//
//  AIGlowModifier.swift
//  Kashat
//

import SwiftUI

struct AIGlowModifier: ViewModifier {
    @State private var rotation: Double = 0
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.purple,
                                    Color.pink,
                                    Color.orange,
                                    Color.blue
                                ]),
                                center: .center,
                                angle: .degrees(rotation)
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.6),
                                    Color.pink.opacity(0.6),
                                    Color.orange.opacity(0.8),
                                    Color.blue.opacity(0.8)
                                ]),
                                center: .center,
                                angle: .degrees(rotation)
                            ),
                            lineWidth: 1
                        )
                )
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func aiGlow(isEnabled: Bool = true) -> some View {
        self.modifier(AIGlowModifier(isEnabled: isEnabled))
    }
}
