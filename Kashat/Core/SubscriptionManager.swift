//
//  SubscriptionManager.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import Foundation
import SwiftUI
import SuperwallKit
internal import Combine
import FirebaseAuth

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPro: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // Configure Superwall (Call this from App Delegate / App Entry)
    func configure(apiKey: String) {
        Superwall.configure(apiKey: apiKey)
        
        // Listen for subscription status changes (Combine)
        // We do this AFTER configuration to avoid "Superwall not configured" crash
        Superwall.shared.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                // Use pattern matching to avoid Equatable issues
                if case .active = status {
                    self?.isPro = true
                } else {
                    self?.isPro = false
                }
                
                // NEW: Sync to Firestore if user is logged in
                if let uid = FirebaseManager.shared.user?.uid {
                    FirebaseManager.shared.updateProStatus(uid: uid, isPro: self?.isPro ?? false)
                }
                
                print("💎 Subscription Status Changed: \(status)")
            }
            .store(in: &cancellables)
    }
    
    // Present the Paywall
    func presentPaywall(on root: UIViewController? = nil) {
        // Superwall handles presentation automatically
        Superwall.shared.register(placement: "campaign_trigger")
    }
    
    // Check Pro status with a specific handler (e.g. for specific features)
    // Returns true if action should proceed (User is Pro)
    // Returns false if paywall is presented
    func checkProStatus(from feature: String) -> Bool {
        if isPro {
            return true
        } else {
            // Trigger paywall for this specific feature
            Superwall.shared.register(placement: "feature_locked_\(feature)")
            return false
        }
    }
}
