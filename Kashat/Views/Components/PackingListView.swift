
import SwiftUI

// MARK: - Packing Models
struct PackingList: Identifiable {
    let id = UUID()
    let name: String
    var items: [PackingItem]
}

struct PackingItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    var isChecked: Bool = false
}

// MARK: - Smart Packing List View
struct PackingListView: View {
    let spot: CampingSpot
    let temperature: Double
    let isPro: Bool
    
    @EnvironmentObject var settings: SettingsManager
    @State private var tripDuration: Int = 1
    @State private var groupSize: Int = 1
    @State private var generatedList: PackingList?
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            .padding()
            
            if isPro {
                if let list = generatedList {
                    // Show List
                    packingListContent(list)
                } else {
                    // Show Generator Form
                    generatorForm
                }
            } else {
                // Locked State
                lockedState
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - SubViews
    
    private var generatorForm: some View {
        VStack(spacing: 16) {
            HStack {
                Label(settings.t("مدة الرحلة (أيام)"), systemImage: "clock")
                Spacer()
                Stepper("\(tripDuration)", value: $tripDuration, in: 1...14)
            }
            .foregroundStyle(.white)
            
            HStack {
                Label(settings.t("عدد الأشخاص"), systemImage: "person.2")
                Spacer()
                Stepper("\(groupSize)", value: $groupSize, in: 1...10)
            }
            .foregroundStyle(.white)
            
            Button(action: generateList) {
                if isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Text(settings.t("إنشاء القائمة (AI)"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }
            .disabled(isGenerating)
        }
        .padding()
    }
    
    private func packingListContent(_ list: PackingList) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settings.t("قائمتك المخصصة"))
                    .font(.caption)
                    .foregroundStyle(.green)
                Spacer()
                Button(settings.t("إعادة إنشاء")) {
                    withAnimation { generatedList = nil }
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(list.items) { item in
                        HStack {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isChecked ? .green : .white.opacity(0.5))
                            Text(item.name)
                                .font(.caption)
                                .strikethrough(item.isChecked)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                        .onTapGesture {
                            toggleItem(item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
    
    private var lockedState: some View {
        VStack(spacing: 8) {
            Text(settings.t("لا تنسى شيئاً مهما!"))
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
            
            Text(settings.t("احصل على قوائم تجهيز ذكية مخصصة لطقس وتضاريس هذا المكان مع PRO."))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Logic
    
    private func generateList() {
        isGenerating = true
        
        // Simulate AI Processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            var items: [PackingItem] = []
            
            // Basics
            items.append(PackingItem(name: "خيام (\(Int(ceil(Double(groupSize)/2.0))))", category: "Basics"))
            items.append(PackingItem(name: "ماء للشرب (\(groupSize * tripDuration * 3) لتر)", category: "Basics"))
            items.append(PackingItem(name: "فرش نوم (\(groupSize))", category: "Basics"))
            
            // Weather Based
            if temperature < 15 {
                items.append(PackingItem(name: "ملابس شتوية ثقيلة", category: "Clothing"))
                items.append(PackingItem(name: "حطب إضافي للتدفئة", category: "Heating"))
            } else if temperature > 30 {
                items.append(PackingItem(name: "مظلة شمسية", category: "Protection"))
                items.append(PackingItem(name: "كريم واقي شمس", category: "Protection"))
            }
            
            // Terrain Based (Simple heuristic)
            if spot.type == "كثبان" || spot.type == "صحراء" {
                items.append(PackingItem(name: "منفخ هواء للكفرات", category: "Car"))
                items.append(PackingItem(name: "اشتراك بطارية", category: "Car"))
                items.append(PackingItem(name: "حبل سحب", category: "Car"))
            } else if spot.type == "وادي" || spot.type == "جبل" {
                items.append(PackingItem(name: "حذاء مشي مريح", category: "Clothing"))
                items.append(PackingItem(name: "عصا مشي", category: "Gear"))
            }
            
            // Food
            items.append(PackingItem(name: "عدة قهوة وشاهي", category: "Food"))
            items.append(PackingItem(name: "تمر وسكريات", category: "Food"))
            
            self.generatedList = PackingList(name: "رحلة \(spot.name)", items: items)
            self.isGenerating = false
        }
    }
    
    private func toggleItem(_ item: PackingItem) {
        guard var list = generatedList else { return }
        if let index = list.items.firstIndex(where: { $0.id == item.id }) {
            list.items[index].isChecked.toggle()
            generatedList = list
        }
    }
}
