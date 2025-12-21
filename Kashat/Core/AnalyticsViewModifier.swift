//
//  AnalyticsViewModifier.swift
//  Kashat
//
//  Created by Assistant on 21/11/2025.
//

import SwiftUI
import FirebaseAnalytics

struct AnalyticsViewModifier: ViewModifier {
    let screenName: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                FirebaseManager.shared.logEvent(name: AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: screenName,
                    AnalyticsParameterScreenClass: screenName
                ])
            }
    }
}

extension View {
    func trackScreen(name: String) -> some View {
        self.modifier(AnalyticsViewModifier(screenName: name))
    }
}
