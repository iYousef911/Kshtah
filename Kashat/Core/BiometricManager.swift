//
//  BiometricManager.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 25/11/2025.
//

import LocalAuthentication
import SwiftUI
internal import Combine

class BiometricManager: ObservableObject {
    static let shared = BiometricManager()
    
    @Published var isUnlocked = false
    @Published var biometricType: LABiometryType = .none
    
    private let context = LAContext()
    
    init() {
        checkBiometricType()
    }
    
    func checkBiometricType() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    func authenticateUser(reason: String = "يرجى المصادقة لفتح التطبيق", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        completion(true)
                    } else {
                        self.isUnlocked = false
                        completion(false)
                    }
                }
            }
        } else {
            // No biometrics available
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
