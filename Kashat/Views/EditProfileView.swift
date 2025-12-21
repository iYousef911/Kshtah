//
//  EditProfileView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 28/11/2025.
//


import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                VStack(spacing: 30) {
                    // Profile Image Picker
                    VStack {
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(width: 120, height: 120).clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else if let url = store.userProfile?.profileImageURL, let validURL = URL(string: url) {
                            AsyncImage(url: validURL) { img in img.resizable().scaledToFill() } placeholder: { Color.gray }
                                .frame(width: 120, height: 120).clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable().scaledToFit()
                                .frame(width: 120, height: 120).foregroundStyle(Color.white.opacity(0.8))
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("تغيير الصورة")
                                .font(.caption).fontWeight(.bold)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.blue).clipShape(Capsule())
                                .foregroundStyle(Color.white)
                        }
                        .onChange(of: selectedItem) {
                            Task { if let data = try? await selectedItem?.loadTransferable(type: Data.self) { withAnimation { selectedImageData = data } } }
                        }
                    }
                    .padding(.top, 40)
                    
                    // Name Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("الاسم").font(.caption).foregroundStyle(Color.white.opacity(0.7))
                        TextField("اسمك", text: $name)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: saveChanges) {
                        HStack {
                            if isSaving { ProgressView().tint(.black) }
                            Text("حفظ التغييرات").fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.white).foregroundStyle(Color.black).clipShape(Capsule())
                    }
                    .disabled(name.isEmpty || isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("تعديل الملف")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() }.foregroundStyle(Color.white) } }
            .onAppear {
                // Load existing name
                if let currentName = store.userProfile?.name {
                    name = currentName
                }
            }
        }
    }
    
    func saveChanges() {
        isSaving = true
        store.updateProfile(name: name, imageData: selectedImageData)
        
        // Delay dismiss to allow upload time (in real app, use completion handler)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSaving = false
            dismiss()
        }
    }
}
