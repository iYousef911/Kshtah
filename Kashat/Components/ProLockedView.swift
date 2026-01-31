//
//  ProLockedView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import SwiftUI

struct ProLockedView<Content: View>: View {
    @StateObject private var subscription = SubscriptionManager.shared
    let featureName: String
    let content: Content
    
    init(feature: String, @ViewBuilder content: () -> Content) {
        self.featureName = feature
        self.content = content()
    }
    
    var body: some View {
        if subscription.isPro {
            content
        } else {
            ZStack {
                content
                    .blur(radius: 8)
                    .disabled(true)
                
                Button(action: {
                    SubscriptionManager.shared.presentPaywall()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                        
                        Text("Unlock with PRO")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                }
            }
            // Trigger paywall logic on appear? Or just let user tap lock?
            // User tap is better UX.
        }
    }
}
