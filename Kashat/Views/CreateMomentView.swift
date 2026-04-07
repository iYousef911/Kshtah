//
//  CreateMomentView.swift
//  Kashat
//

import SwiftUI
import PhotosUI

struct CreateMomentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var caption: String = ""
    @State private var isUploading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Picker
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 300)
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 50))
                                        Text(settings.t("اضغط لاختيار صورة من الكشتة"))
                                            .font(.headline)
                                    }
                                    .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        
                        // Caption Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settings.t("اكتب وصفاً ليومياتك:"))
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            TextField(settings.t("كم كانت درجة الحرارة؟ وين كشتّ؟..."), text: $caption, axis: .vertical)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                        
                        // Submit Button
                        Button(action: uploadMoment) {
                            HStack {
                                if isUploading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(settings.t("نشر اليوميات"))
                                        .font(.title3.bold())
                                    Image(systemName: "paperplane.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                        }
                        .disabled(selectedImageData == nil || isUploading)
                        .opacity(selectedImageData == nil ? 0.5 : 1.0)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(settings.t("يوميات جديدة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t("إلغاء")) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func uploadMoment() {
        guard let data = selectedImageData else { return }
        isUploading = true
        
        store.postGlobalMoment(imageData: data, caption: caption.isEmpty ? nil : caption)
        
        // Simulating upload time for UX feedback since Firebase handles it async without a block in AppDataStore
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isUploading = false
            dismiss()
        }
    }
}
