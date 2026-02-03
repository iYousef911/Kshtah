import SwiftUI

struct AIInsightView: View {
    let insight: String?
    let isPro: Bool
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text(settings.t("تحليل الكشتة الذكي"))
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
                Text(insight ?? settings.t("لا يتوفر تحليل لهذا المكان حالياً."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 8) {
                    Text(settings.t("هذا التحليل متاح لمشتركي PRO فقط"))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(settings.t("احصل على نصائح ذكية بناءً على الطقس والموقع."))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .blur(radius: isPro ? 0 : 1)
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            AIInsightView(insight: "الطقس مثالي لليلة صافية. الرياح هادئة مما يجعلها مناسبة للتخييم فوق الجبال.", isPro: true)
            AIInsightView(insight: "الطقس مثالي لليلة صافية. الرياح هادئة مما يجعلها مناسبة للتخييم فوق الجبال.", isPro: false)
        }
        .padding()
    }
    .environmentObject(SettingsManager())
}
