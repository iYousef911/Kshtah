//
//  handles.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 28/11/2025.
//


import Foundation
import PassKit
import SwiftUI
internal import Combine

import Foundation
import PassKit
import SwiftUI

// This class handles the Apple Pay sheet
class PaymentManager: NSObject, ObservableObject {
    // FIX: Changed to return String? (Payment ID) for the backend
    typealias PaymentCompletionHandler = (String?) -> Void
    var completionHandler: PaymentCompletionHandler?
    
    // Status to update UI
    @Published var paymentStatus = PKPaymentAuthorizationStatus.failure
    
    // REPLACE with your actual Publishable Key from Moyasar Dashboard
    private let moyasarApiKey = "pk_test_vcJun5....."
    
    // Create the payment request
    func startPayment(amount: Double, label: String, completion: @escaping PaymentCompletionHandler) {
        completionHandler = completion
        
        // 1. Configure the Request
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.Kashat" // Change this in your Apple Developer Account
        request.supportedNetworks = [.visa, .masterCard, .mada, .amex] // Critical for Saudi Arabia
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "SA"
        request.currencyCode = "SAR"
        
        // 2. Set the Amount
        let paymentItem = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount))
        request.paymentSummaryItems = [paymentItem]
        
        // 3. Present the Controller
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        controller.present { presented in
            if !presented {
                print("Apple Pay not available")
                // Ensure UI update happens on Main Thread
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Moyasar API Call
    private func processPaymentWithMoyasar(payment: PKPayment, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.moyasar.com/v1/payments") else { return }
        guard let tokenString = String(data: payment.token.paymentData, encoding: .utf8) else { completion(nil); return }
        
        // Moyasar expects amount in Halalas (SAR * 100)
        // Hardcoded 10 SAR (1000) for testing/MVP consistency with backend
        let body: [String: Any] = [
            "amount": 1000,
            "currency": "SAR",
            "description": "Kashat Wallet TopUp",
            "source": [
                "type": "applepay",
                "token": tokenString
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // FIX: Ensure strict Basic Auth format (username:password) -> (API_KEY:)
        let loginString = "\(moyasarApiKey):"
        guard let loginData = loginString.data(using: String.Encoding.utf8) else {
            print("Error creating auth string")
            completion(nil)
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { completion(nil); return }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            // Parse Response to get ID
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check for success status
                if let status = json["status"] as? String, status == "paid", let id = json["id"] as? String {
                    print("✅ Moyasar Payment ID: \(id)")
                    completion(id) // Return the ID!
                } else if let message = json["message"] as? String {
                    // API returned an error message
                    print("❌ Moyasar API Error: \(message)")
                    if let type = json["type"] as? String {
                         print("❌ Error Type: \(type)")
                    }
                    completion(nil)
                } else {
                    print("❌ Unknown JSON response")
                    completion(nil)
                }
            } else {
                if let dataString = String(data: data, encoding: .utf8) {
                    print("❌ JSON Parsing Failed. Raw Response: \(dataString)")
                }
                completion(nil)
            }
        }.resume()
    }
}

// Delegate Methods to handle the response
extension PaymentManager: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        // Call Moyasar API
        processPaymentWithMoyasar(payment: payment) { paymentId in
            DispatchQueue.main.async {
                if let paymentId = paymentId {
                    self.paymentStatus = .success
                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                    self.completionHandler?(paymentId)
                } else {
                    self.paymentStatus = .failure
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    self.completionHandler?(nil)
                }
            }
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // Ensure dismissal happens on Main Thread
        DispatchQueue.main.async {
            controller.dismiss(completion: nil)
        }
    }
}

// SwiftUI Button Wrapper
struct ApplePayButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .checkout, paymentButtonStyle: .white)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}
