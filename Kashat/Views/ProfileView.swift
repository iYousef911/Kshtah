//
//  ProfileView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import FirebaseAuth
import UserNotifications // NEW: Import for local notifications
import AuthenticationServices // NEW: For Passkey Registration
import LocalAuthentication
internal import Combine

struct ProfileView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var biometricManager = BiometricManager.shared // NEW: Biometric Logic
    
    // App Lock State
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    
    // Sheet States
    @State private var showMyBookings = false
    @State private var showFavorites = false
    @State private var showWalletSheet = false
    @State private var isDepositTransaction = true
    @State private var showEditProfile = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showCopyAlert = false // NEW: Alert state
    @State private var showDeleteAccountAlert = false // NEW: Delete Account Alert
    
    // Live Data Accessors
    var userName: String { store.userProfile?.name ?? "جاري التحميل..." }
    var balance: Double { store.userProfile?.balance ?? 0.0 }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                // Note: If this view is pushed in a tab view that already has the background,
                // you might not need another one, but keeping it ensures consistency if used standalone.
                // In main ContentView we have a global background, so we can omit it here or keep it
                // if we want the scrollview to sit nicely on top.
                // Assuming ContentView manages the main background, let's keep the content clean.
                // However, if this view is presented in a way that needs background, add LiquidBackgroundView().
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        settingsListSection
                        authButtonsSection
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            // Sheets
            .sheet(isPresented: $showMyBookings) {
                MyBookingsView().presentationDetents([.large])
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView().presentationDetents([.large])
            }
            .sheet(isPresented: $showWalletSheet) {
                WalletTransactionView(isDeposit: isDepositTransaction).presentationDetents([.medium])
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView().presentationDetents([.medium])
            }
            .sheet(isPresented: $showTerms) {
                LegalView(title: "شروط الاستخدام", content: LegalData.termsOfService)
            }
            .sheet(isPresented: $showPrivacy) {
                LegalView(title: "سياسة الخصوصية", content: LegalData.privacyPolicy)
            }
        }
        .trackScreen(name: "Profile") // Analytic Screen
    }
    
    // MARK: - Extracted Views
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 110, height: 110)
                
                if let url = store.userProfile?.profileImageURL, let validURL = URL(string: url) {
                    AsyncImage(url: validURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .glassEffect(GlassStyle.regular, in: Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .glassEffect(GlassStyle.regular, in: Circle())
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showEditProfile = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.title)
                                .background(Circle().fill(Color.white))
                        }
                    }
                }
                .frame(width: 100, height: 100)
            }
            
            VStack(spacing: 4) {
                HStack {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                    
                    if store.userProfile?.isAdmin == true {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title3)
                            .foregroundStyle(Color.blue)
                    }
                    
                    if SubscriptionManager.shared.isPro || store.userProfile?.isPro == true {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Capsule())
                    }
                }
                
                Text(store.userProfile?.phoneNumber ?? "")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .glassEffect(GlassStyle.regular, in: Capsule())
            }
        }
        .padding(.top, 20)
    }
    
    private var settingsListSection: some View {
        VStack(spacing: 4) {
            Button(action: { showMyBookings = true }) {
                SettingsRow(icon: "cube.box.fill", title: settings.t("طلباتي"), subtitle: settings.t("عرض سجل التأجير"))
            }
            .buttonStyle(.plain)
            
            Button(action: { showFavorites = true }) {
                SettingsRow(icon: "heart.fill", title: settings.t("المفضلة"), subtitle: "١٢ \(settings.t("مكان"))")
            }
            .buttonStyle(.plain)
            
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
            
            Button(action: { settings.toggleLanguage() }) {
                SettingsRow(icon: "globe", title: settings.t("اللغة"), subtitle: settings.language == "ar" ? "العربية" : "English", hasChevron: false)
            }
            .buttonStyle(.plain)
            
            SettingsRow(icon: "bell.fill", title: settings.t("الإشعارات"), isToggle: true, isOn: $settings.notificationsEnabled)
            
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
            SettingsRow(icon: "faceid", title: settings.t("قفل التطبيق"), isToggle: true, isOn: $isAppLockEnabled)
            
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
            
            Button(action: {
                let email = store.supportEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                if let url = URL(string: "mailto:\(email)") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    } else {
                        UIPasteboard.general.string = email
                        showCopyAlert = true
                    }
                }
            }) {
                SettingsRow(icon: "questionmark.circle.fill", title: settings.t("المساعدة والدعم"), subtitle: settings.t("تواصل معنا"))
            }
            .buttonStyle(.plain)
            .alert(settings.t("تم نسخ البريد الإلكتروني ✅"), isPresented: $showCopyAlert) {
                Button(settings.t("حسناً"), role: .cancel) { }
            } message: {
                Text("لم نتمكن من فتح تطبيق البريد. تم نسخ (\(store.supportEmail)) إلى الحافظة.")
            }
            
            Button(action: { showPrivacy = true }) {
                SettingsRow(icon: "hand.raised.fill", title: settings.t("سياسة الخصوصية"), subtitle: "")
            }
            .buttonStyle(.plain)
            
            Button(action: { showTerms = true }) {
                SettingsRow(icon: "doc.text.fill", title: settings.t("شروط الاستخدام"), subtitle: "")
            }
            .buttonStyle(.plain)
            
            if store.userProfile?.isAdmin == true {
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                Button(action: { store.seedGearData() }) {
                    SettingsRow(icon: "server.rack", title: settings.t("تحديث البيانات (Admin)"), subtitle: "Seed Gear", hasChevron: false)
                }
                .buttonStyle(.plain)
                
                Button(action: { store.seedDefaultCategories() }) {
                    SettingsRow(icon: "arrow.counterclockwise.circle.fill", title: settings.t("إعادة تعيين التصنيفات"), subtitle: "Reset Categories", hasChevron: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }
    
    private var authButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showDeleteAccountAlert = true }) {
                Text(settings.t("حذف الحساب"))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(GlassStyle.regular.interactive(), in: Capsule())
            }
            .alert(settings.t("حذفه نهائياً؟"), isPresented: $showDeleteAccountAlert) {
                Button(settings.t("إلغاء"), role: .cancel) { }
                Button(settings.t("حذف"), role: .destructive) { deleteAccount() }
            } message: {
                Text(settings.t("سيتم حذف جميع بياناتك ولا يمكن التراجع."))
            }
            
            Button(action: {
                try? FirebaseManager.shared.auth.signOut()
            }) {
                Text(settings.t("تسجيل خروج"))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(GlassStyle.regular.interactive(), in: Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
    }
    
    // MARK: - Test Notification Logic
    func sendTestNotification() {
        // Request Permission first (just in case)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "تجربة كشتات ⛺️"
                content.body = "هذا إشعار تجريبي للتأكد من أن التنبيهات تعمل لديك."
                content.sound = .default
                
                // Trigger after 5 seconds
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
                print("Notification scheduled! Background the app now.")
            } else {
                print("Notification permission denied")
            }
        }
    }

    
    // MARK: - Account Deletion
    func deleteAccount() {
        FirebaseManager.shared.deleteAccount { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
                // Optionally show error alert
            } else {
                // Determine logic handled by auth listener in ContentView or here
            }
        }
    }
}
    


// MARK: - Helper Components

struct WalletActionLabel: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
        .foregroundStyle(Color.white)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isToggle: Bool
    let hasChevron: Bool
    @Binding var isOn: Bool
    
    init(icon: String, title: String, subtitle: String? = nil, isToggle: Bool = false, hasChevron: Bool = true, isOn: Binding<Bool> = .constant(false)) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isToggle = isToggle
        self.hasChevron = hasChevron
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.white)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            if isToggle {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(Color.blue)
            } else if hasChevron {
                Image(systemName: "chevron.left") // RTL arrow
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle()) // Makes the whole row tappable
    }
}
#Preview {
    ProfileView()
}
