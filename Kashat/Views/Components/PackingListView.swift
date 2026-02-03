import SwiftUI

struct PackingListItem: Identifiable {
    let id = UUID()
    let name: String
    var isChecked: Bool = false
}

struct PackingListView: View {
    let spot: CampingSpot
    let temperature: Double
    let isPro: Bool
    @EnvironmentObject var settings: SettingsManager
    @State private var items: [PackingListItem] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "backpack.fill")
                    .foregroundStyle(.orange)
                Text(settings.t("قائمة التجهيز الذكية"))
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
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Text(settings.t("جاري تجهيز قائمتك..."))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach($items) { $item in
                            Button(action: {
                                withAnimation { item.isChecked.toggle() }
                            }) {
                                HStack {
                                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isChecked ? .green : .white.opacity(0.4))
                                    Text(item.name)
                                        .strikethrough(item.isChecked)
                                        .foregroundStyle(item.isChecked ? .white.opacity(0.4) : .white)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    Text(settings.t("تعتمد هذه القائمة على حالة الطقس وتضاريس الموقع."))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 4)
                }
            } else {
                VStack(spacing: 8) {
                    Text(settings.t("لا تنسى شيئاً أبداً!"))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(settings.t("ميزة PRO لإنشاء قوائم ذكية تناسب وجهتك وظروفك."))
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
        .onAppear {
            if isPro {
                loadItems()
            }
        }
    }
    
    private func loadItems() {
        Task {
            let suggestedItems = await AIService.shared.generatePackingList(
                spotName: spot.name,
                location: spot.location,
                type: spot.type,
                temperature: temperature
            )
            DispatchQueue.main.async {
                self.items = suggestedItems.map { PackingListItem(name: $0) }
                self.isLoading = false
            }
        }
    }
}
