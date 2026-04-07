//
//  ChecklistsDashboardView.swift
//  Kashat
//

import SwiftUI

struct ChecklistsDashboardView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showNewChecklistAlert = false
    @State private var newChecklistTitle = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if store.checklists.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "list.bullet.clipboard.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("لا توجد قوائم سفر!")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                Text("أضف قائمة جديدة للتأكد من عدم نسيان أغراضك كالشاي والقهوة.")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach($store.checklists) { $checklist in
                                NavigationLink(destination: ChecklistDetailView(checklist: $checklist)) {
                                    ChecklistCard(checklist: checklist)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(settings.t("قوائم الكشتة"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNewChecklistAlert = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .onAppear {
                store.loadDefaultChecklists()
            }
            .alert("قائمة كشتة جديدة", isPresented: $showNewChecklistAlert) {
                TextField("الاسم (مثلاً: طلعة بر، شتاء، الخ)", text: $newChecklistTitle)
                Button("إلغاء", role: .cancel) { }
                Button("إضافة") {
                    if !newChecklistTitle.isEmpty {
                        let newList = TripChecklist(name: newChecklistTitle, items: [], emoji: "📍")
                        withAnimation {
                            store.checklists.insert(newList, at: 0)
                        }
                        newChecklistTitle = ""
                    }
                }
            }
        }
    }
}

struct ChecklistCard: View {
    let checklist: TripChecklist
    
    var body: some View {
        HStack(spacing: 16) {
            Text(checklist.emoji)
                .font(.largeTitle)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(checklist.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack {
                    Text("\(Int(checklist.progress * 100))%")
                        .font(.caption.bold())
                    ProgressView(value: checklist.progress)
                        .tint(checklist.progress == 1.0 ? .green : .blue)
                }
                
                Text("\(checklist.items.filter { $0.isCompleted }.count) من \(checklist.items.count) مكتملة")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.left")
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ChecklistDetailView: View {
    @Binding var checklist: TripChecklist
    @State private var newItemTitle = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack {
                // Header Progress
                HStack {
                    VStack(alignment: .leading) {
                        Text(checklist.name)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("\(Int(checklist.progress * 100))% مكتملة")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    ProgressView(value: checklist.progress)
                        .progressViewStyle(.circular)
                        .tint(checklist.progress == 1.0 ? .green : .blue)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
                
                // Add Item
                HStack {
                    TextField("إضافة غرض جديد...", text: $newItemTitle)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                        .onSubmit { addItem() }
                    
                    Button(action: addItem) {
                        Image(systemName: "plus")
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal)
                
                List {
                    ForEach($checklist.items) { $item in
                        HStack {
                            Button(action: {
                                withAnimation(.spring()) {
                                    item.isCompleted.toggle()
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(item.isCompleted ? .green : .white.opacity(0.5))
                            }
                            
                            Text(item.title)
                                .font(.body)
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .white.opacity(0.5) : .white)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indices in
                        checklist.items.remove(atOffsets: indices)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationTitle(checklist.emoji)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    private func addItem() {
        if !newItemTitle.isEmpty {
            withAnimation {
                checklist.items.append(ChecklistItem(title: newItemTitle))
                newItemTitle = ""
            }
        }
    }
}
