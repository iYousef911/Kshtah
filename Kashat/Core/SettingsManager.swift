//
//  SettingsManager.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import SwiftUI
internal import Combine

class SettingsManager: ObservableObject {
    // Save to UserDefaults automatically
    @AppStorage("appLanguage") var language: String = "ar" // "ar" or "en"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    
    // Computed property for Layout Direction
    var layoutDirection: LayoutDirection {
        return language == "ar" ? .rightToLeft : .leftToRight
    }
    
    // Computed property for Locale
    var locale: Locale {
        return Locale(identifier: language)
    }
    
    // Action to toggle
    func toggleLanguage() {
        // Add a slight delay/animation feel
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            language = (language == "ar") ? "en" : "ar"
        }
    }
    
    // Helper for localized strings (Simulation for this demo)
    // In a real app, you would use Localizable.strings
    func t(_ key: String) -> String {
        if language == "ar" {
            return key // Assuming keys are Arabic defaults for now
        } else {
            // Simple dictionary for English mapping (Demo purpose)
            let dict: [String: String] = [
                "الرئيسية": "Home",
                "السوق": "Market",
                "الخريطة": "Map",
                "حسابي": "Profile",
                "مرحباً،": "Hello,",
                "وين وجهتك الجاية؟": "Where to next?",
                "أماكن مميزة": "Featured Spots",
                "معدات مقترحة": "Recommended Gear",
                "مخيمات": "Camps",
                "كثبان": "Dunes",
                "وادي": "Valley",
                "جبل": "Mountain",
                "شاطئ": "Beach",
                "الكل": "All",
                "حطب": "Wood",
                "سوق الكشتة": "Camping Market",
                "طلباتي": "My Orders",
                "المفضلة": "Favorites",
                "اللغة": "Language",
                "الإشعارات": "Notifications",
                "المساعدة والدعم": "Support",
                "تسجيل خروج": "Logout",
                "محفظتي": "My Wallet",
                "شحن": "Top Up",
                "سحب": "Withdraw",
                
                // Notifications & Alerts
                "لا توجد إشعارات جديدة": "No new notifications",
                "سنخبرك عند وجود عروض جديدة": "We'll let you know when there are new offers",
                "نسخنا لك كود الخصم! 🎁": "Discount code copied! 🎁",
                "شكراً": "Thanks",
                "تم نسخ كود": "Code copied",
                "للحافظة. استمتع بكشتتك!": "to clipboard. Enjoy your trip!",
                
                // Home Feed
                "عرض خاص! 🎉": "Special Offer! 🎉",
                "خصم 10% على أول كشتة": "10% off your first trip",
                "استخدمه الآن": "Use Now",
                "لا توجد أماكن في هذا التصنيف": "No spots in this category",
                
                // Marketplace
                "ابحث عن خيمة، ماطور، حطب...": "Search for tent, generator, wood...",
                "خيام": "Tents",
                "كهرباء": "Power",
                "طبخ": "Cooking",
                "شواء": "Grilling",
                "انقاذ": "Rescue",
                "أخرى": "Others",
                "لا توجد منتجات": "No products found",
                "تحديث": "Refresh",
                "قريبا ...": "Coming Soon ...",
                "نعمل على تجهيز سوق الكشتة لخدمتكم بشكل أفضل": "We are working on preparing the camping market to serve you better",
                "ريال": "SAR",
                "يوم": "day",
                
                // Profile & Settings
                "عرض سجل التأجير": "View rental history",
                "قفل التطبيق": "App Lock",
                "تواصل معنا": "Contact us",
                "سياسة الخصوصية": "Privacy Policy",
                "شروط الاستخدام": "Terms of Use",
                "تحديث البيانات (Admin)": "Update Data (Admin)",
                "رفع المنتجات للسيرفر": "Upload products to server",
                "حذف الحساب": "Delete Account",
                "حذف الحساب نهائياً؟": "Delete account permanently?",
                "سيتم حذف جميع بياناتك ولا يمكن التراجع عن هذا الإجراء.": "All your data will be deleted and this action cannot be undone.",
                "حذف": "Delete",
                "إلغاء": "Cancel",
                "مكان": "places",
                "تم نسخ البريد الإلكتروني ✅": "Email copied ✅",
                "حسناً": "OK"
            ]
            return dict[key] ?? key
        }
    }
}
