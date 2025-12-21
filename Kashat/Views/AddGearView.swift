//
//  AddGearView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 28/11/2025.
//


import SwiftUI
import PhotosUI

struct AddGearView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var priceString = ""
    @State private var selectedCategory = "خيام"
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploading = false
    
    let categories = ["خيام", "كهرباء", "طبخ", "شواء", "انقاذ", "أخرى"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.white.gradient)
                                .shadow(color: Color.orange.opacity(0.5), radius: 20)
                            
                            Text("اعرض معداتك")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                            
                            Text("اربح من تأجير معداتك الزائدة")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.7))
                        }
                        .padding(.top, 30)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Name
                            GlassTextField(icon: "tag.fill", placeholder: "اسم المنتج (مثلاً: خيمة عمودين)", text: $name)
                            
                            // Price
                            HStack {
                                Image(systemName: "banknote.fill")
                                    .foregroundStyle(Color.white.opacity(0.6))
                                TextField("السعر اليومي (ريال)", text: $priceString)
                                    .keyboardType(.numberPad)
                                    .foregroundStyle(Color.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // Category Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("التصنيف").font(.caption).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(action: { withAnimation { selectedCategory = cat } }) {
                                                Text(cat)
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .glassEffect(
                                                        selectedCategory == cat ? GlassStyle.regular.interactive().tint(Color.orange.opacity(0.4)) : GlassStyle.regular.interactive(),
                                                        in: Capsule()
                                                    )
                                                    .foregroundStyle(Color.white)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            
                            // Image Picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("صورة المنتج").font(.caption).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal)
                                
                                // FIX: Use 'data' instead of shadowing 'selectedImageData'
                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable().scaledToFill().frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                        
                                        Button(action: {
                                            withAnimation {
                                                self.selectedItem = nil
                                                self.selectedImageData = nil
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(Color.white.opacity(0.8)).shadow(radius: 5).padding(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                } else {
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus").font(.largeTitle)
                                            Text("رفع صورة").font(.caption).fontWeight(.bold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 150)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal)
                                    }
                                    .onChange(of: selectedItem) {
                                        Task {
                                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                                withAnimation { selectedImageData = data }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Submit Button
                        Button(action: submitGear) {
                            HStack {
                                if isUploading { ProgressView().tint(.white) }
                                Text("عرض للإيجار").fontWeight(.bold)
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.green : Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                        }
                        .disabled(!isValid || isUploading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إلغاء") { dismiss() }.foregroundStyle(Color.white)
                }
            }
        }
    }
    
    var isValid: Bool {
        !name.isEmpty && !priceString.isEmpty && selectedImageData != nil
    }
    
    func submitGear() {
        guard let price = Int(priceString), let data = selectedImageData else { return }
        isUploading = true
        
        store.addNewGear(name: name, price: price, category: selectedCategory, imageData: data)
        
        // Simulate slight delay for UX then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isUploading = false
            dismiss()
        }
    }
}

#Preview {
    AddGearView()
}
