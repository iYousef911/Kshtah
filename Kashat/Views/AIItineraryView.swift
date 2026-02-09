import SwiftUI

struct AIItineraryView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var carType = "4x4"
    @State private var duration = 2
    @State private var groupSize = 4
    @State private var generatedItinerary = ""
    @State private var isGenerating = false
    
    let carTypes = ["4x4", "Sedan", "SUV"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .symbolEffect(.pulse)
                            
                            Text(settings.t("خبير الكشته الذكي"))
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            
                            Text(settings.t("خطة كشتة مخصصة لك بالكامل بضغطة زر"))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 20) {
                            FormRow(title: "نوع السيارة") {
                                Picker("", selection: $carType) {
                                    ForEach(carTypes, id: \.self) { car in
                                        Text(car).tag(car)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            FormRow(title: "مدة الكشتة (أيام)") {
                                Stepper("\(duration) \(settings.t("أيام"))", value: $duration, in: 1...7)
                                    .foregroundStyle(.white)
                            }
                            
                            FormRow(title: "عدد الأشخاص") {
                                Stepper("\(groupSize) \(settings.t("أشخاص"))", value: $groupSize, in: 1...15)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Generate Button
                        Button(action: generatePlan) {
                            HStack {
                                if isGenerating {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                    Text(settings.t("جهز لي الخطة!"))
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.5), radius: 10)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal)
                        
                        // Result
                        if !generatedItinerary.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text(settings.t("خطتك المقترحة ⛺️"))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Text(generatedItinerary)
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .lineSpacing(6)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.t("إغلاق")) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func generatePlan() {
        isGenerating = true
        generatedItinerary = ""
        
        Task {
            let result = await AIService.shared.generateItinerary(
                carType: carType,
                duration: duration,
                groupSize: groupSize
            )
            
            await MainActor.run {
                withAnimation(.spring()) {
                    generatedItinerary = result
                    isGenerating = false
                }
            }
        }
    }
}

struct FormRow<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.6))
            content
        }
    }
}
