//
//  LoginView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import CryptoKit
internal import Combine

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
        GeometryReader { geometry in
            ZStack {
                // Unified Background
                LiquidBackgroundView()
                    .ignoresSafeArea()
                
                // Content Overlay
                if geometry.size.width > 600 {
                    // iPad / Landscape / Wide Screen - Immersive Split
                    HStack(spacing: 0) {
                        // Left Side: Branding (Floating)
                        BrandingView()
                            .frame(width: geometry.size.width * 0.5)
                            .frame(maxHeight: .infinity)
                        
                        // Right Side: Login Form (Glass Card)
                        ZStack {
                            ScrollView {
                                VStack(spacing: 40) {
                                    Spacer(minLength: 50)
                                    InputFormView
                                    Spacer(minLength: 50)
                                }
                                .padding(.horizontal, 40) // Internal padding for form
                                .frame(minHeight: geometry.size.height)
                            }
                        }
                        .frame(width: geometry.size.width * 0.5)
                    }
                } else {
                    // iPhone / Portrait / Narrow Screen - Stacked Immersive
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer(minLength: 60)
                            BrandingView()
                                .padding(.bottom, 40)
                            
                            InputFormView
                                .padding(.horizontal, 24)
                                .padding(.bottom, 40)
                            Spacer(minLength: 20)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .animation(.spring, value: showOtpField)
        .animation(.spring, value: showError)
        .sheet(isPresented: $showTerms) { LegalView(title: "شروط الاستخدام", content: LegalData.termsOfService) }
        .sheet(isPresented: $showPrivacy) { LegalView(title: "سياسة الخصوصية", content: LegalData.privacyPolicy) }
    }
    
    @ViewBuilder
    func BrandingView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "tent.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(Color.white.gradient)
                .shadow(color: Color.blue.opacity(0.6), radius: 30, x: 0, y: 10)
                
            Text("كشتات")
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                
            Text("رفيقك في البر")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(Color.white.opacity(0.8))
        }
    }
    
    var InputFormView: some View {
        VStack(spacing: 30) {
            
            // Container for Inputs
            VStack(spacing: 25) {
                if !showOtpField { phoneInputView } else { otpInputView }
            }
            .padding(30)
            .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 30))
            
            if showError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorMessage)
                }
                .font(.caption)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .transition(.opacity)
            }
            
            // Social Login Section
             if !showOtpField {
                 HStack(spacing: 15) {
                     Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                     Text("أو").font(.caption).foregroundStyle(Color.white.opacity(0.7))
                     Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                 }
                 .padding(.vertical, 10)
                 
                 VStack(spacing: 12) {
                     // Apple Sign In
                     Button(action: startAppleSignIn) {
                         HStack {
                             Image(systemName: "apple.logo")
                                 .font(.title2)
                             Text("تسجيل الدخول بـ Apple")
                                 .fontWeight(.semibold)
                         }
                         .frame(maxWidth: .infinity)
                         .padding()
                         .background(Color.white)
                         .foregroundStyle(Color.black)
                         .clipShape(Capsule())
                     }
                     
                     // Google Sign In
                     Button(action: startGoogleSignIn) {
                         HStack {
                             Image("google") // Custom Google Logo
                                 .resizable()
                                 .scaledToFit()
                                 .frame(width: 24, height: 24)
                             Text("تسجيل الدخول بـ Google")
                                 .fontWeight(.semibold)
                         }
                         .frame(maxWidth: .infinity)
                         .padding()
                         .background(Color.white)
                         .foregroundStyle(Color.black)
                         .clipShape(Capsule())
                     }
                 }
             }
            
            // Legal Footer
            if !showOtpField {
                VStack(spacing: 10) {
                    Text("بتسجيل الدخول، أنت توافق على")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    HStack(spacing: 20) {
                        Button("شروط الاستخدام") { showTerms = true }
                        Button("سياسة الخصوصية") { showPrivacy = true }
                    }
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                    .underline(true, color: .white.opacity(0.3))
                }
            }
        }
    }
    
    var phoneInputView: some View {
        VStack(spacing: 25) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("تأكيد الرمز ورقم الهاتف")
                    .font(.title2.bold())
                    .foregroundStyle(Color.white)
                Text("سيتم إرسال رمز التحقق عبر رسالة نصية")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Split Inputs
            HStack(spacing: 12) {
                // Country Code Box
                HStack(spacing: 4) {
                    Text("🇸🇦")
                    Text("+966")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
//                        .scaleEffect(x: -1, y: 1) // Mirror for RTL layout consistency if needed, but numbers are LTR usually. 
                        // Actually, purely visual +966 is fine without mirroring if alignment is correct.
                        // Let's keep it simple.
                }
                .padding()
                .frame(height: 55)
                .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                
                // Phone Number Box
                TextField("55...", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .foregroundStyle(Color.white)
                    .accentColor(.white)
                    .colorScheme(.dark)
                    .padding()
                    .frame(height: 55)
                    .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Main Action Button
            Button(action: sendCode) {
                if isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Text("التالي") // "Next"
                        .fontWeight(.bold)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 55)
            .background(Color.blue) // Use Blue to match reference "Next" button color, or keep White? 
            // Reference had Blue button. Let's use Blue for a fresh look, or White to match Glass theme.
            // User asked "make design similar to this one" -> Reference has Blue button.
            // I will use Blue.
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(phoneNumber.count < 9 || isProcessing) // Adjusted count check for 55... (9 digits)
            .opacity(phoneNumber.count < 9 ? 0.6 : 1.0)
        }
    }
    
    var otpInputView: some View {
        VStack(spacing: 20) {
            Text("التحقق من الرمز").font(.headline).foregroundStyle(Color.white)
            Text("تم إرسال الرمز إلى \(phoneNumber)").font(.caption).foregroundStyle(Color.white.opacity(0.7))
            TextField("XXXXXX", text: $otpCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white)
                .accentColor(.white)
                .colorScheme(.dark)
                .padding()
                .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16))
                .onChange(of: otpCode) { if otpCode.count == 6 { verifyOtp() } }
            
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
    
    // MARK: - Social Login Handlers
    // MARK: - Social Login Handlers
    func startAppleSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        
        // Retain the controller in the coordinator to ensure it stays alive
        coordinator.currentController = authorizationController
        
        authorizationController.performRequests()
    }
    
    func startGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            // Note: GoogleSignIn 7.0+ uses 'user.idToken?.tokenString'
            // Check GoogleSignIn version. Assuming standard recent version.
            
            let accessToken = user.accessToken.tokenString
            
            // Call Firebase
             FirebaseManager.shared.signInWithGoogle(idToken: idToken, accessToken: accessToken) { error in
                 if let error = error {
                     self.errorMessage = error.localizedDescription
                     self.showError = true
                 } else {
                     // Success handled by Auth State Listener in App
                 }
             }
        }
    }
    

    
    // --- Apple Sign In Helpers ---
    // Removed shadowing var: @State private var currentNonce: String?
    @StateObject private var coordinator = SignInWithAppleCoordinator()
}

// MARK: - SignInWithAppleCoordinator
class SignInWithAppleCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    // Keep a strong reference to the controller to prevent premature deallocation
    var currentController: ASAuthorizationController?
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // More robust scene finding
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        return windowScene?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
             // ... (Apple ID Logic)
             handleAppleID(credential: appleIDCredential)
        }
        currentController = nil // Release reference
    }
    
    func handleAppleID(credential: ASAuthorizationAppleIDCredential) {
            guard let nonce = currentNonce else {
                print("Invalid state: A login callback was received, but no login request was sent.")
                return
            }
            
            guard let appleIDToken = credential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // Extract Full Name
            var fullName: String? = nil
            if let nameComponents = credential.fullName {
                fullName = PersonNameComponentsFormatter().string(from: nameComponents)
            }
            
            FirebaseManager.shared.signInWithApple(idToken: idTokenString, nonce: nonce, fullName: fullName) { error in
                if let error = error {
                    print("Error authenticating: \(error.localizedDescription)")
                }
            }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error.localizedDescription)")
        currentController = nil // Release reference
    }
}

// Global Helper for Nonce
private var currentNonce: String?

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
    }
    
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    let nonce = randomBytes.map { charset[Int($0) % charset.count] }
    return String(nonce)
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}

#Preview {
    LoginView()
}
