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
                        headerSection
                        
                        formContent
                        
                        actionButton
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
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(Color.white.gradient)
                .shadow(color: Color.orange.opacity(0.5), radius: 20)
            
            Text("اعرض معداتك")
                .font(.title)
                .bold()
                .foregroundStyle(Color.white)
            
            Text("اربح من تأجير معداتك الزائدة")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.top, 30)
    }
    
    @ViewBuilder
    private var formContent: some View {
        if #available(iOS 26.0, *) {
            VStack(spacing: 16) {
                GlassTextField(icon: "tag.fill", placeholder: "اسم المنتج (مثلاً: خيمة عمودين)", text: $name)
                
                priceField
                
                categoryField
                
                imagePickerSection
            }
            .padding()
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)
        } else {
            // Fallback on earlier versions
            VStack(spacing: 16) {
                GlassTextField(icon: "tag.fill", placeholder: "اسم المنتج (مثلاً: خيمة عمودين)", text: $name)
                
                priceField
                
                categoryField
                
                imagePickerSection
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)

        }
    }
    
    @ViewBuilder
    private var priceField: some View {
        HStack {
            Image(systemName: "banknote.fill")
                .foregroundStyle(Color.white.opacity(0.6))
            TextField("السعر اليومي (ريال)", text: $priceString)
                .keyboardType(.numberPad)
                .foregroundStyle(Color.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("التصنيف").font(.caption).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { cat in
                        Button(action: { withAnimation { selectedCategory = cat } }) {
                            if #available(iOS 26.0, *) {
                                Text(cat)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .glassEffect(
                                        selectedCategory == cat ? .clear.interactive().tint(Color.orange.opacity(0.4)) : .clear.interactive(),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(Color.white)
                            } else {
                                // Fallback on earlier versions
                                Text(cat)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)

                                    .foregroundStyle(Color.white)

                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var imagePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("صورة المنتج").font(.caption).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal)
            
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    
                    Button(action: {
                        withAnimation {
                            self.selectedItem = nil
                            self.selectedImageData = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.white.opacity(0.8))
                            .shadow(radius: 5)
                            .padding(10)
                    }
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus").font(.largeTitle)
                        Text("رفع صورة").font(.caption).bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                    .foregroundStyle(Color.white)
                }
                .onChange(of: selectedItem) {
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                withAnimation { selectedImageData = data }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button(action: submitGear) {
            HStack {
                if isUploading { ProgressView().tint(.white) }
                Text("عرض للإيجار").bold()
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValid ? Color.green : Color.gray.opacity(0.3))
            .clipShape(.capsule)
        }
        .disabled(!isValid || isUploading)
        .padding(.horizontal)
        .padding(.top, 20)
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
