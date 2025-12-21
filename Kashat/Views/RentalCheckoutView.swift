//
//  RentalCheckoutView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//


import SwiftUI
import FirebaseAuth

struct RentalCheckoutView: View {
    let item: GearItem
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400)
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    // Payment Method State
    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    
    // NEW: Payment Manager
    @StateObject private var paymentManager = PaymentManager()
    @State private var errorMessage = ""
    
    enum PaymentMethod {
        case applePay
        case creditCard
    }
    
    var days: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(1, components.day ?? 1)
    }
    
    var totalCost: Double { return Double(days * item.pricePerDay) }
    var serviceFee: Double { return totalCost * store.serviceFeePercentage } // Dynamic Fee
    var grandTotal: Double { return totalCost + serviceFee }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                if showSuccess {
                    SuccessView { dismiss() }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Item Summary
                            HStack(spacing: 15) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)).frame(width: 80, height: 80)
                                    
                                    // Handle Item Image (URL vs SF Symbol)
                                    if item.imageName.starts(with: "http"), let url = URL(string: item.imageName) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Color.white.opacity(0.1)
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        Image(systemName: item.imageName).font(.title).foregroundStyle(Color.white)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.headline).foregroundStyle(Color.white)
                                    Text("المالك: \(item.ownerName)").font(.caption).foregroundStyle(Color.white.opacity(0.6))
                                    Text("\(item.pricePerDay) ﷼ / يوم").font(.caption).fontWeight(.bold).foregroundStyle(Color.green)
                                }
                                Spacer()
                            }
                            .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
                            
                            // Date Selection
                            VStack(alignment: .leading, spacing: 10) {
                                Text("مدة الإيجار").font(.headline).foregroundStyle(Color.white).padding(.horizontal)
                                VStack(spacing: 0) {
                                    DatePicker("من", selection: $startDate, displayedComponents: .date).environment(\.locale, Locale(identifier: "ar_SA")).colorScheme(.dark).padding()
                                    Divider().background(Color.white.opacity(0.1))
                                    DatePicker("إلى", selection: $endDate, in: startDate..., displayedComponents: .date).environment(\.locale, Locale(identifier: "ar_SA")).colorScheme(.dark).padding()
                                }
                                .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
                            }
                            
                            // Price Breakdown
                            VStack(spacing: 12) {
                                RowInfo(label: "الإيجار (\(days) أيام)", value: "\(Int(totalCost)) ﷼")
                                RowInfo(label: "رسوم الخدمة (\(Int(store.serviceFeePercentage * 100))٪)", value: "\(Int(serviceFee)) ﷼") // Dynamic Label
                                Divider().background(Color.white.opacity(0.2))
                                RowInfo(label: "الإجمالي", value: "\(Int(grandTotal)) ﷼", isBold: true)
                            }
                            .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
                            
                            // Payment Methods
                            VStack(alignment: .leading, spacing: 12) {
                                Text("طريقة الدفع").font(.headline).foregroundStyle(Color.white).padding(.horizontal)
                                
                                HStack(spacing: 15) {
                                    // Apple Pay Button
                                    Button(action: { withAnimation { selectedPaymentMethod = .applePay } }) {
                                        PaymentOption(
                                            icon: "applelogo",
                                            title: "Apple Pay",
                                            isSelected: selectedPaymentMethod == .applePay
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Credit Card Button
                                    Button(action: { withAnimation { selectedPaymentMethod = .creditCard } }) {
                                        PaymentOption(
                                            icon: "creditcard.fill",
                                            title: "البطاقة",
                                            isSelected: selectedPaymentMethod == .creditCard
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Error Message Display
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                            }
                            
                            Color.clear.frame(height: 100)
                        }
                        .padding(.top)
                    }
                    
                    // Pay Button
                    VStack {
                        Spacer()
                        if selectedPaymentMethod == .applePay {
                            // Use Custom Action Button that triggers Apple Pay Manager
                            Button(action: processApplePay) {
                                PayButtonContent(isProcessing: isProcessing, amount: grandTotal, icon: "applelogo")
                            }
                            .disabled(isProcessing)
                        } else {
                            // Use Regular Button for Credit Card (Simulation)
                            Button(action: processCreditCard) {
                                PayButtonContent(isProcessing: isProcessing, amount: grandTotal, icon: "creditcard.fill")
                            }
                            .disabled(isProcessing)
                        }
                    }
                }
            }
            .navigationTitle("إتمام الطلب")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() }.foregroundStyle(Color.white) } }
        }
    }
    
    // MARK: - Apple Pay Logic
    func processApplePay() {
        isProcessing = true
        errorMessage = ""
        
        // 1. Trigger Apple Pay Sheet
        paymentManager.startPayment(amount: grandTotal, label: "تأجير: \(item.name)") { paymentId in
            
            // 2. Handle Result (on Main Thread)
            if let paymentId = paymentId {
                // 3. Verify with Backend (Optional: Call Cloud Function here if needed)
                // For now, we trust the ID returned means success
                print("Apple Pay Success! ID: \(paymentId)")
                
                // 4. Complete Booking
                completeBooking()
            } else {
                isProcessing = false
                errorMessage = "تم إلغاء الدفع أو فشل العملية"
            }
        }
    }
    
    // MARK: - Credit Card Logic (Simulated)
    func processCreditCard() {
        withAnimation { isProcessing = true }
        errorMessage = ""
        
        // Simulate Network Delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // In a real app, here you would show the Stripe/Moyasar Card Form
            // For MVP, we assume success
            completeBooking()
        }
    }
    
    // MARK: - Common Booking Completion
    func completeBooking() {
        // Call AppDataStore to save the booking and update wallet/analytics
        // Note: We pass totalPrice. The store handles deducting from wallet balance IF we were using wallet.
        // But here we just PAID directly.
        // So store.addBooking logic might need adjustment if it *always* deducts from wallet.
        // If users pay directly via Apple Pay, we shouldn't deduct from their *Kashat Wallet* balance,
        // we should just record the booking.
        
        // However, based on your AppDataStore implementation:
        // It calls 'firebase.deductBalance'.
        // If the user paid via Apple Pay here, they shouldn't be double-charged from wallet.
        // For this specific flow (Direct Payment), we might need a 'addPaidBooking' function.
        
        // OPTION: We treat this Apple Pay transaction as a "Top Up + Pay" instant operation.
        // 1. Top Up Wallet with Amount.
        // 2. Then Deduct Amount for Booking.
        
        // Let's simplify: Just save the booking directly since they paid external money.
        
        guard let uid = FirebaseManager.shared.user?.uid else { return }
        
        let newBooking = Booking(
            id: UUID(),
            item: item,
            startDate: startDate,
            endDate: endDate,
            totalPrice: grandTotal,
            status: .active,
            isRated: false
        )
        
        // Save to Cloud
        FirebaseManager.shared.saveBooking(uid: uid, booking: newBooking)
        
        // Record Revenue (15%)
        let commission = grandTotal * 0.15
        FirebaseManager.shared.recordRevenue(amount: commission, source: "Direct Rental: \(item.name)")
        
        // Update Local State
        DispatchQueue.main.async {
            withAnimation {
                store.bookings.insert(newBooking, at: 0)
                isProcessing = false
                showSuccess = true
            }
        }
    }
}

// MARK: - Subviews

struct PayButtonContent: View {
    let isProcessing: Bool
    let amount: Double
    let icon: String
    
    var body: some View {
        HStack {
            if isProcessing {
                ProgressView().tint(.black)
            } else {
                Text("دفع \(Int(amount)) ﷼")
                    .fontWeight(.bold)
                Image(systemName: icon)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .foregroundStyle(Color.black)
        .clipShape(Capsule())
        .padding()
    }
}

struct RowInfo: View {
    let label: String, value: String; var isBold: Bool = false
    var body: some View { HStack { Text(label).foregroundStyle(Color.white.opacity(isBold ? 1.0 : 0.7)); Spacer(); Text(value).fontWeight(isBold ? .bold : .regular).foregroundStyle(isBold ? Color.green : Color.white) } }
}

struct PaymentOption: View {
    let icon: String, title: String, isSelected: Bool
    var body: some View {
        HStack { Image(systemName: icon); Text(title) }
            .frame(maxWidth: .infinity).padding()
            .background(Color.white.opacity(isSelected ? 0.2 : 0.05))
            .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(isSelected ? 0.5 : 0.0), lineWidth: 1))
            .foregroundStyle(Color.white)
    }
}

struct SuccessView: View {
    var onDismiss: () -> Void
    var body: some View { VStack(spacing: 20) { Image(systemName: "checkmark.circle.fill").font(.system(size: 100)).foregroundStyle(Color.green).symbolEffect(.bounce, options: .nonRepeating); Text("تم الدفع بنجاح!").font(.title).fontWeight(.bold).foregroundStyle(Color.white); Text("تم إرسال طلبك للمالك، بيجيك رد قريب.").foregroundStyle(Color.white.opacity(0.7)).multilineTextAlignment(.center); Button("الرجوع للسوق", action: onDismiss).fontWeight(.bold).padding(.horizontal, 40).padding(.vertical, 12).background(Color.white.opacity(0.2)).clipShape(Capsule()).foregroundStyle(Color.white).padding(.top, 20) }.padding() }
}
