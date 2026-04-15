//
//  SmartNotificationEngine.swift
//  Kashat
//
//  AI-powered local notification engine.
//  Generates personalised, context-aware notification copy so users
//  never see the same boring message twice.
//

import Foundation
import UserNotifications
import WeatherKit
import CoreLocation

// MARK: - Notification Trigger Types
enum NotificationTriggerType: String, CaseIterable {
    case weekendReminder    = "weekend_reminder"    // Thu/Fri evening
    case perfectWeather     = "perfect_weather"     // Nice weather detected
    case newSpot            = "new_spot"            // A new spot was added
    case badgeMilestone     = "badge_milestone"     // User unlocked a badge
    case inactivityNudge    = "inactivity_nudge"   // User hasn't opened app in N days
    case moonAlert          = "moon_alert"          // Full/super moon tonight
    case convoyInvite       = "convoy_invite"       // Someone started a convoy nearby
}

// MARK: - Smart Notification Engine
actor SmartNotificationEngine {
    static let shared = SmartNotificationEngine()
    private let center = UNUserNotificationCenter.current()
    private let workerURL = URL(string: "https://kashat-ai-worker.youssefzx.workers.dev")!
    
    // Keys for UserDefaults to track scheduling
    private let lastScheduledKey = "last_notification_scheduled_date"
    private let totalScheduledKey = "total_notifications_scheduled"
    
    // Min hours between notification scheduling runs (prevents spamming)
    private let minHoursBetweenScheduling: Double = 20
    
    // MARK: - Main Entry Point
    /// Call this once from `AppDataStore.onAppear` or `AppDelegate.applicationDidBecomeActive`.
    /// It self-rate-limits so it won't spam the system.
    func scheduleSmartNotifications(
        userName: String,
        favoriteCount: Int,
        lastActiveDate: Date?,
        topSpots: [String],          // Names of user's favourite spots
        unlockedBadges: [String]
    ) async {
        let authorized = await requestPermissionIfNeeded()
        guard authorized else { return }
        
        // Rate-limit: don't reschedule within minHoursBetweenScheduling hours
        if let last = UserDefaults.standard.object(forKey: lastScheduledKey) as? Date,
           Date().timeIntervalSince(last) < minHoursBetweenScheduling * 3600 {
            return
        }
        
        // Clear pending application notifications before rescheduling
        center.removePendingNotificationRequests(withIdentifiers: NotificationTriggerType.allCases.map { $0.rawValue })
        
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now) // 1=Sun … 7=Sat
        
        // Context signal bag
        let context = NotificationContext(
            userName: firstName(from: userName),
            hour: hour,
            weekday: weekday,
            favoriteCount: favoriteCount,
            topSpot: topSpots.first ?? "الطبيعة",
            daysSinceLastActive: daysSince(lastActiveDate),
            unlockedBadges: unlockedBadges,
            now: now
        )
        
        // Decide which notifications make sense to schedule right now
        var scheduled = 0
        
        // 1. Weekend reminder (schedule Thursday & Friday evenings)
        if weekday == 5 || weekday == 6 { // Thu = 5, Fri = 6 in Gregorian (Saudi weekend)
            await scheduleNotification(type: .weekendReminder, context: context, fireInSeconds: eveningFireOffset(hour: hour))
            scheduled += 1
        }
        
        // 2. Inactivity nudge (> 3 days without opening)
        if context.daysSinceLastActive > 3 {
            await scheduleNotification(type: .inactivityNudge, context: context, fireInSeconds: 60 * 60 * 2) // 2 hours from now
            scheduled += 1
        }
        
        // 3. Moon alert (simple approximation: full moons are every ~29.5 days from a known epoch)
        if isApproxFullMoon(date: now) {
            await scheduleNotification(type: .moonAlert, context: context, fireInSeconds: hoursUntilSunset())
            scheduled += 1
        }
        
        // 4. Allow one unconditional nudge if nothing else fires this session
        if scheduled == 0 {
            await scheduleNotification(type: .weekendReminder, context: context, fireInSeconds: 60 * 60 * 8) // 8 hours later
        }
        
        UserDefaults.standard.set(now, forKey: lastScheduledKey)
        UserDefaults.standard.set(
            (UserDefaults.standard.integer(forKey: totalScheduledKey)) + scheduled,
            forKey: totalScheduledKey
        )
    }
    
    // MARK: - Immediate (event-driven) Notifications
    /// Call this when a specific app event happens (badge unlock, convoy invite, new spot).
    func sendEventNotification(type: NotificationTriggerType, context: NotificationContext) async {
        await scheduleNotification(type: type, context: context, fireInSeconds: 2)
    }
    
    // MARK: - Core Scheduler
    private func scheduleNotification(
        type: NotificationTriggerType,
        context: NotificationContext,
        fireInSeconds: TimeInterval
    ) async {
        let (title, body) = await generateCopy(for: type, context: context)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Attach a category for interactive actions
        content.categoryIdentifier = "kashat_smart"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fireInSeconds), repeats: false)
        let request = UNNotificationRequest(identifier: type.rawValue, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("✅ Scheduled '\(type.rawValue)' notification in \(Int(fireInSeconds))s")
        } catch {
            print("❌ Failed to schedule '\(type.rawValue)': \(error)")
        }
    }
    
    // MARK: - AI Copy Generation
    private func generateCopy(
        for type: NotificationTriggerType,
        context: NotificationContext
    ) async -> (title: String, body: String) {
        
        // Build a concise, well-scoped prompt
        let prompt = buildPrompt(for: type, context: context)
        
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10  // Notifications must be fast
        
        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": 0.9,    // High creativity for varied copy
            "max_tokens": 80       // Title + body, very short
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? String {
                
                return parseAIResponse(content, fallback: staticFallback(for: type, context: context))
            }
        } catch {
            print("⚠️ AI notification generation failed, using fallback: \(error.localizedDescription)")
        }
        
        return staticFallback(for: type, context: context)
    }
    
    // MARK: - Prompt Builder
    private func buildPrompt(for type: NotificationTriggerType, context: NotificationContext) -> String {
        let base = """
        أنت كاتب إشعارات ذكي لتطبيق "كشات" للتخييم والرحلات البرية في السعودية.
        اكتب إشعاراً قصيراً وجذاباً بالعربية (لهجة سعودية بيضاء خفيفة).
        الصيغة المطلوبة (سطران فقط):
        العنوان: [نص قصير لا يزيد عن 5 كلمات]
        الرسالة: [جملة واحدة جذابة لا تتجاوز 12 كلمة]
        
        معلومات المستخدم:
        - الاسم: \(context.userName)
        - مواقعه المفضلة: \(context.topSpot)
        - عدد الأماكن المفضلة: \(context.favoriteCount)
        """
        
        let typeContext: String
        switch type {
        case .weekendReminder:
            typeContext = "- السبب: يوم الإجازة اليوم (خميس أو جمعة)، ذكّره بالطلعة"
        case .perfectWeather:
            typeContext = "- السبب: الطقس مثالي اليوم للتخييم، حفّزه"
        case .newSpot:
            typeContext = "- السبب: تم إضافة موقع كشتة جديد قريب منه، شوّقه"
        case .inactivityNudge:
            typeContext = "- السبب: ما فتح التطبيق من \(context.daysSinceLastActive) أيام، ذكّره بطريقة ودية مشوّقة"
        case .badgeMilestone:
            typeContext = "- السبب: فتح وساماً جديداً، هنّئه وشجّعه على المزيد"
        case .moonAlert:
            typeContext = "- السبب: الليلة ليلة بدر (قمر كامل)، شوّقه لليالي البر"
        case .convoyInvite:
            typeContext = "- السبب: أحد الكشاتة بدأ قافلة، ادعه للانضمام"
        }
        
        return "\(base)\n\(typeContext)\n\nلا تكرر نفس الأسلوب دائماً، كن مبدعاً."
    }
    
    // MARK: - Response Parser
    private func parseAIResponse(_ text: String, fallback: (String, String)) -> (String, String) {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        var title = fallback.0
        var body  = fallback.1
        
        for line in lines {
            if line.hasPrefix("العنوان:") {
                title = line.replacingOccurrences(of: "العنوان:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("الرسالة:") {
                body = line.replacingOccurrences(of: "الرسالة:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        return (title, body)
    }
    
    // MARK: - Static Fallbacks (used if AI is offline)
    private func staticFallback(for type: NotificationTriggerType, context: NotificationContext) -> (String, String) {
        // Each type has a small pool so they rotate
        let pools: [NotificationTriggerType: [(String, String)]] = [
            .weekendReminder: [
                ("وين الكشتة؟ ⛺️", "الإجازة جت، \(context.topSpot) مستنيتك!"),
                ("طلعة اليوم؟ 🌿", "يوم الإجازة ما يكتمل إلا بنار وشاي وسما مفتوحة."),
                ("مع مين الكشتة؟ 🏕️", "نهاية الأسبوع ما أحلى ما البر!")
            ],
            .inactivityNudge: [
                ("وحشتنا يا \(context.userName)! 👋", "مرت \(context.daysSinceLastActive) أيام، الكشتة شايلاك."),
                ("في مواقع جديدة بانتظارك 📍", "عدنا بمفاجآت تستاهل الطلعة."),
                ("البر ينادي 🌅", "شوقنا لك! شوف وين تقدر تكشت ويانا.")
            ],
            .moonAlert: [
                ("ليلة البدر الليلة 🌕", "ما في ليلة أجمل لكشتة تحت ضوء القمر."),
                ("القمر كامل الليلة! 🌕", "سما صافية ونجوم و\(context.topSpot) تسوى.")
            ],
            .badgeMilestone: [
                ("وسام جديد! 🏅", "خطوة إضافية في رحلتك كمستكشف كشتة."),
                ("مبروك الإنجاز 🎉", "استمر وافتح المزيد من الأوسمة.")
            ],
            .newSpot: [
                ("موقع جديد اكتُشف 📍", "ضيف \(context.topSpot) لمفضلتك قبل ما يكتشفه ثاني."),
                ("كشتة جديدة تستناك ✨", "ما تبي تكون أول من يزور هذا الموقع؟")
            ],
            .perfectWeather: [
                ("طقس مثالي اليوم ☀️", "الفرصة ذهبية للطلعة، لا تفوّتها."),
                ("الجو بطل 😍", "\(context.topSpot) في أبهى صورها اليوم!")
            ],
            .convoyInvite: [
                ("القافلة طالعة! 🚗", "انضم الحين قبل ما يبعدون."),
                ("قافلة كشتة بدأت 🚙", "كشاتة قريبين منك بدأوا القافلة، لحقهم!")
            ]
        ]
        
        let options = pools[type] ?? [("كشات ⛺️", "الكشتة مستنياك!")]
        return options.randomElement() ?? options[0]
    }
    
    // MARK: - Helpers
    private func requestPermissionIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        
        // Do NOT auto-prompt the user here (e.g. via requestAuthorization).
        // The permission prompt should only be triggered by Onboarding or explicit setting toggles.
        return false
    }
    
    private func firstName(from full: String) -> String {
        full.components(separatedBy: " ").first ?? full
    }
    
    private func daysSince(_ date: Date?) -> Int {
        guard let date else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
    }
    
    private func eveningFireOffset(hour: Int) -> TimeInterval {
        // Target 7 PM local, minimum 30 min from now
        let targetHour = 19
        let hoursUntilEvening = max(0, targetHour - hour)
        return max(30 * 60, Double(hoursUntilEvening) * 3600)
    }
    
    private func hoursUntilSunset() -> TimeInterval {
        // Rough estimate: sunset ~6 PM in KSA
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let hoursLeft = max(1, 18 - hour)
        return Double(hoursLeft) * 3600
    }
    
    /// Very rough full-moon detection (±1 day accuracy)
    private func isApproxFullMoon(date: Date) -> Bool {
        // Known full moon epoch: Jan 13 2025 00:00 UTC
        let epoch = Date(timeIntervalSince1970: 1736726400)
        let lunarCycle: Double = 29.53059
        let daysSinceEpoch = date.timeIntervalSince(epoch) / 86400
        let phase = daysSinceEpoch.truncatingRemainder(dividingBy: lunarCycle)
        // Full moon is around day 14-16
        return phase >= 13.5 && phase <= 16.0
    }
    
    // MARK: - Register Interactive Notification Actions
    func registerNotificationCategories() {
        let openAction = UNNotificationAction(
            identifier: "OPEN_MAP",
            title: "📍 شوف الخريطة",
            options: .foreground
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "لاحقاً",
            options: .destructive
        )
        let category = UNNotificationCategory(
            identifier: "kashat_smart",
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - Context Model (plain struct, safe to pass around)
struct NotificationContext {
    let userName: String
    let hour: Int
    let weekday: Int
    let favoriteCount: Int
    let topSpot: String
    let daysSinceLastActive: Int
    let unlockedBadges: [String]
    let now: Date
}
