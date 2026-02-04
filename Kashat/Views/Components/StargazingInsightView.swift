import SwiftUI

struct StargazingInsightView: View {
    let bortleScale: Int?
    let isPro: Bool
    let moonOverride: MoonPhase? // NEW: For precision from WeatherKit
    @EnvironmentObject var settings: SettingsManager
    @State private var moon: MoonPhase
    
    init(bortleScale: Int?, isPro: Bool, moonOverride: MoonPhase? = nil) {
        self.bortleScale = bortleScale
        self.isPro = isPro
        self.moonOverride = moonOverride
        self._moon = State(initialValue: moonOverride ?? MoonPhaseService.shared.getMoonPhase())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles.cosmic")
                    .foregroundStyle(.purple)
                Text(settings.t("حالة رصد النجوم"))
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if !isPro {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            if isPro {
                HStack(spacing: 20) {
                    // Moon Info
                    VStack(alignment: .center, spacing: 4) {
                        Image(systemName: moon.icon)
                            .font(.system(size: 30))
                            .foregroundStyle(.yellow)
                        Text(moon.name)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(width: 80)
                    
                    Divider().background(Color.white.opacity(0.3))
                    
                    // Dark Sky Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(settings.t("تلوث ضوئي (Bortle):"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(bortleScale ?? 5)/9")
                                .font(.caption.bold())
                                .foregroundStyle(bortleColor)
                        }
                        
                        Text(darkSkyVerdict)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text(settings.t("اكتشف روعة سماء المملكة"))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(settings.t("معلومات حصرية لـ PRO عن التلوث الضوئي وظروف الرصد."))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var bortleColor: Color {
        guard let scale = bortleScale else { return .yellow }
        if scale <= 2 { return .green }
        if scale <= 4 { return .yellow }
        return .orange
    }
    
    private var darkSkyVerdict: String {
        guard let scale = bortleScale else { return "ظروف الرصد غير متوفرة." }
        
        // If moon is too bright (> 60% illumination), it ruins stargazing regardless of Bortle
        if moon.illumination > 60 {
            return "القمر ساطع اليوم (\(moon.illumination)%). قد يصعب رؤية النجوم البعيدة حتى في المناطق المظلمة."
        }
        
        let moonGood = moon.isDark
        
        if scale <= 3 && moonGood {
            return "سماء مظلمة جداً ومثالية! فرصة رائعة لتصوير المجرة اليوم. 🌌"
        } else if scale <= 5 {
            return "ظروف رصد جيدة. يمكن رؤية العديد من النجوم بوضوح."
        } else {
            return "تلوث ضوئي مرتفع في هذه المنطقة. قد تصعب رؤية الأجرام البعيدة."
        }
    }
}
