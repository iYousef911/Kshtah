//
//  LoginView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @ObservedObject var firebase = FirebaseManager.shared
    @State private var phoneNumber = "+966"
    @State private var otpCode = ""
    @State private var isProcessing = false
    @State private var showOtpField = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // NEW: Legal Sheets
    @State private var showPrivacy = false
    @State private var showTerms = false
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                VStack(spacing: 10) {
                    Image(systemName: "tent.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(Color.white.gradient)
                        .shadow(color: Color.blue.opacity(0.5), radius: 20)
                    Text("كشتات").font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(Color.white)
                    Text("رفيقك في البر").font(.title3).foregroundStyle(Color.white.opacity(0.7))
                }
                
                // Input Container
                VStack(spacing: 20) {
                    if !showOtpField { phoneInputView } else { otpInputView }
                }
                .padding(30).glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 30)).padding(.horizontal)
                
                if showError { Text(errorMessage).foregroundStyle(Color.red).font(.caption).padding().background(Color.black.opacity(0.6)).clipShape(Capsule()).transition(.opacity) }
                
                Spacer()
                
                // NEW: Legal Footer
                if !showOtpField {
                    VStack(spacing: 5) {
                        Text("بتسجيل الدخول، أنت توافق على")
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.6))
                        
                        HStack(spacing: 20) {
                            Button("شروط الاستخدام") { showTerms = true }
                            Button("سياسة الخصوصية") { showPrivacy = true }
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .animation(.spring, value: showOtpField)
        .animation(.spring, value: showError)
        .sheet(isPresented: $showTerms) { LegalView(title: "شروط الاستخدام", content: LegalData.termsOfService) }
        .sheet(isPresented: $showPrivacy) { LegalView(title: "سياسة الخصوصية", content: LegalData.privacyPolicy) }
    }
    
    var phoneInputView: some View {
        VStack(spacing: 20) {
            Text("تسجيل الدخول").font(.headline).foregroundStyle(Color.white).frame(maxWidth: .infinity, alignment: .leading)
            HStack { Text("🇸🇦").font(.title2); Divider().background(Color.white); TextField("+96655...", text: $phoneNumber).keyboardType(.phonePad).foregroundStyle(Color.white) }
            .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16))
            
            Button(action: sendCode) { if isProcessing { ProgressView().tint(.black) } else { Text("إرسال الرمز").fontWeight(.bold).frame(maxWidth: .infinity) } }
            .padding().background(Color.white).foregroundStyle(Color.black).clipShape(Capsule()).disabled(phoneNumber.count < 10 || isProcessing).opacity(phoneNumber.count < 10 ? 0.5 : 1.0)
        }
    }
    
    var otpInputView: some View {
        VStack(spacing: 20) {
            Text("التحقق من الرمز").font(.headline).foregroundStyle(Color.white)
            Text("تم إرسال الرمز إلى \(phoneNumber)").font(.caption).foregroundStyle(Color.white.opacity(0.7))
            TextField("XXXXXX", text: $otpCode).keyboardType(.numberPad).multilineTextAlignment(.center).font(.system(size: 30, weight: .bold, design: .monospaced)).foregroundStyle(Color.white).padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16)).onChange(of: otpCode) { if otpCode.count == 6 { verifyOtp() } }
            
            Button(action: verifyOtp) { if isProcessing { ProgressView().tint(.black) } else { Text("تحقق").fontWeight(.bold).frame(maxWidth: .infinity) } }
            .padding().background(Color.white).foregroundStyle(Color.black).clipShape(Capsule()).disabled(otpCode.count < 6 || isProcessing)
            Button("تغيير الرقم") { withAnimation { showOtpField = false } }.font(.caption).foregroundStyle(Color.white.opacity(0.6))
        }
    }
    
    func sendCode() {
        isProcessing = true; showError = false
        firebase.startPhoneAuth(phoneNumber: phoneNumber) { error in isProcessing = false; if let error = error { errorMessage = error.localizedDescription; showError = true } else { showOtpField = true } }
    }
    
    func verifyOtp() {
        isProcessing = true; showError = false
        firebase.verifyCode(code: otpCode) { error in
            isProcessing = false
            if let error = error { errorMessage = error.localizedDescription; showError = true }
            else {
                if let user = firebase.auth.currentUser {
                    firebase.createUserProfile(user: user)
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
