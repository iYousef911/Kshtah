//
//  WalletTransactionView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import SwiftUI
import FirebaseAuth

struct WalletTransactionView: View {
    let isDeposit: Bool // true = Top Up, false = Withdraw
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    // NEW: Payment Manager
    @StateObject private var paymentManager = PaymentManager()
    
    @State private var amountString = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    var title: String { isDeposit ? "شحن المحفظة" : "سحب الرصيد" }
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: isDeposit ? "plus.circle.fill" : "arrow.up.forward.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(isDeposit ? Color.green.gradient : Color.orange.gradient)
                        .shadow(color: (isDeposit ? Color.green : Color.orange).opacity(0.5), radius: 20)
                    
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                }
                .padding(.top, 40)
                
                if showSuccess {
                    // Success View
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.green)
                        Text("تمت العملية بنجاح")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                    .transition(.scale)
                } else {
                    // Input Form
                    VStack(spacing: 20) {
                        Text("المبلغ (ريال)")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(Color.red)
                                .font(.caption)
                        }
                        
                        // Action Buttons
                        if isDeposit {
                            // APPLE PAY BUTTON
                            ApplePayButton(action: performApplePay)
                                .frame(height: 50)
                                .clipShape(Capsule())
                                .disabled(amountString.isEmpty || isProcessing)
                        } else {
                            // Regular Withdraw Button
                            Button(action: performWithdrawal) {
                                if isProcessing {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("تأكيد السحب")
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundStyle(Color.black)
                            .clipShape(Capsule())
                            .disabled(amountString.isEmpty || isProcessing)
                        }
                    }
                    .padding()
                    .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .blur(radius: store.isWalletEnabled ? 0 : 10) // NEW: Conditional Blur
            .allowsHitTesting(store.isWalletEnabled) // NEW: Conditional Interaction
            .disabled(!store.isWalletEnabled)
            
            // Coming Soon Overlay
            if !store.isWalletEnabled { // NEW: Conditional Overlay
                VStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(.bottom, 10)
                    
                    Text("قريبا ...")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    
                    Text("نعمل على تجهيز المحفظة لخدمتكم بشكل أفضل")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            }
            
            // Close Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .trackScreen(name: "Wallet") // Analytic Screen
    }
    
    // Logic for Apple Pay Top-Up
    func performApplePay() {
        guard let amount = Double(amountString), amount > 0 else { return }
        isProcessing = true
        
        // 1. Start Apple Pay
        paymentManager.startPayment(amount: amount, label: "شحن رصيد كشتات") { paymentId in
            if let paymentId = paymentId {
                // 2. Payment Succeeded, now Verify with Backend
                FirebaseManager.shared.callTopUpWallet(paymentId: paymentId, amount: amount) { success in
                    if success {
                        // 3. Backend Verified & Updated Balance
                        // Refresh Local Data
                        if let uid = FirebaseManager.shared.user?.uid {
                            store.loadUserData(uid: uid)
                        }
                        finishTransaction(success: true)
                    } else {
                        errorMessage = "فشل التحقق من الدفع"
                        finishTransaction(success: false)
                    }
                }
            } else {
                errorMessage = "فشلت عملية الدفع"
                finishTransaction(success: false)
            }
        }
    }
    
    // Logic for Withdrawal
    func performWithdrawal() {
        guard let amount = Double(amountString), amount > 0 else { return }
        isProcessing = true
        store.performWalletTransaction(amount: amount, isDeposit: false) { success in
            finishTransaction(success: success)
        }
    }
    
    
    
    func finishTransaction(success: Bool) {
        withAnimation {
            isProcessing = false
            if success {
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
            } else {
                errorMessage = isDeposit ? "حدث خطأ" : "رصيدك غير كافٍ"
            }
        }
    }
}
#Preview {
    WalletTransactionView(isDeposit: true)
}
