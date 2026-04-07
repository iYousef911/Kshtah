//
//  GamificationPassportSection.swift
//  Kashat
//

import SwiftUI

struct GamificationPassportSection: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    
    // Hardcoded List of App Gamification Badges
    let availableBadges: [GamificationBadge] = [
        GamificationBadge(id: "explorer", name: "مستكشف مبتدئ", description: "أضف أول مكان إلى مفضلتك", icon: "map.fill"),
        GamificationBadge(id: "pro_explorer", name: "مكتشف محترف", description: "اكتشف ٥ أماكن كشتة أو أكثر!", icon: "star.fill"),
        GamificationBadge(id: "gear_master", name: "خبير المعدات", description: "استأجر معدات ٣ مرات", icon: "tent.fill"),
        GamificationBadge(id: "social_butterfly", name: "اجتماعي", description: "شارك ٥ يوميات في الكشتة", icon: "camera.macro"),
        GamificationBadge(id: "community_voice", name: "صوت المجتمع", description: "قيّم ٣ أماكن كشتة", icon: "hand.thumbsup.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settings.t("جواز الكشتة 🛂"))
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                let unlockedCount = store.userProfile?.unlockedBadges.count ?? 0
                Text("\(unlockedCount) / \(availableBadges.count)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(availableBadges) { badge in
                        let isUnlocked = store.userProfile?.unlockedBadges.contains(badge.id) ?? false
                        
                        BadgeCard(badge: badge, isUnlocked: isUnlocked)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .padding(.vertical)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }
}

struct BadgeCard: View {
    let badge: GamificationBadge
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 80, height: 80)
                    .shadow(color: isUnlocked ? .orange.opacity(0.5) : .clear, radius: 10)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 30))
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.2))
            }
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.caption.bold())
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.5))
                    .lineLimit(1)
                
                Text(badge.description)
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                    .lineLimit(2)
            }
        }
        .frame(width: 110)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? .orange.opacity(0.3) : .white.opacity(0.05), lineWidth: 1)
        )
    }
}
