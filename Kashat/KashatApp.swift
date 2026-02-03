//
//  KashatApp.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging // NEW IMPORT
import OneSignalFramework
import SuperwallKit

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate { // NEW Protocol
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // NEW: Request Notification Permissions
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()
        
        
        // Enable verbose logging for debugging (remove in production)
               OneSignal.Debug.setLogLevel(.LL_VERBOSE)
               // Initialize with your OneSignal App ID
               OneSignal.initialize("425a7450-e204-4d77-b5f3-9f9246ae9d3f", withLaunchOptions: launchOptions)
               // Use this method to prompt for push notifications.
               // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
               OneSignal.Notifications.requestPermission({ accepted in
                 print("User accepted notifications: \(accepted)")
               }, fallbackToSettings: false)

        
        
        // Initialize Superwall (Kashat PRO)
        // REPLACE with your actual Superwall API Key
        SubscriptionManager.shared.configure(apiKey: "pk_pH9m0yDYMxyMNhrQd3qjE")
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        Messaging.messaging().apnsToken = deviceToken // NEW: Sync with FCM
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }
    
    // NEW: Receive FCM Token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("🔥 Firebase Cloud Messaging Token: \(token)")
            // Save this to Firestore if user is logged in
            if let uid = Auth.auth().currentUser?.uid {
                FirebaseManager.shared.updateFCMToken(uid: uid, token: token)
            }
        }
    }
}

@main
struct KashatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = AppDataStore()
    @StateObject private var settings = SettingsManager()
    @StateObject private var theme = ThemeManager()
    
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showSplash = false }
                            }
                        }
                } else {
                    // Critical Checks
                    if store.isMaintenanceMode {
                        MaintenanceView()
                    } else if isUpdateRequired(minVersion: store.minRequiredVersion) {
                        ForceUpdateView()
                    } else {
                        Group {
                            if !hasSeenOnboarding { OnboardingView() } else { ContentView() }
                        }
                        .environment(\.layoutDirection, settings.layoutDirection)
                        .environment(\.locale, settings.locale)
                        .onOpenURL { url in if Auth.auth().canHandle(url) {} }
                    }
                }
            }
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(theme)
            .preferredColorScheme(.dark)
        }
    }
    
    // Version Check Logic
    func isUpdateRequired(minVersion: String) -> Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return currentVersion.compare(minVersion, options: .numeric) == .orderedAscending
    }
}

// MARK: - Critical Overlay Views

struct MaintenanceView: View {
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse)
                
                Text("تحت الصيانة 🚧")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                Text("نقوم بتحسين الكشتة! راجعين لك قريباً.")
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

struct ForceUpdateView: View {
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("تحديث إجباري 📲")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                Text("عشان تستمتع بأفضل تجربة، لازم تحدث التطبيق لآخر نسخة.")
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("تحديث الآن") {
                    // Open App Store
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id6756845059") {
                        UIApplication.shared.open(url)
                    }
                }
                .fontWeight(.bold)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.white)
                .foregroundStyle(.blue)
                .clipShape(Capsule())
            }
            .padding()
        }
    }
}
