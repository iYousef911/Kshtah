//
//  AddSpotView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct AddSpotView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    var coordinate: CLLocationCoordinate2D? // NEW: Optional coordinate
    
    @State private var name = ""
    @State private var locationDesc = ""
    @State private var selectedType = "روضة"
    @State private var selectedImageURL: String?
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploading = false // NEW: Loading state
    
    let types = ["روضة", "كثبان", "وادي", "جبل", "شاطئ"]
    
    let presetImages = [
        "https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1545562086-f93eb53bb3c9?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.white.gradient)
                                .shadow(color: Color.blue.opacity(0.5), radius: 20)
                            Text("أضف مكان جديد").font(.title).fontWeight(.bold).foregroundStyle(Color.white)
                            Text("شاركنا أماكنك المفضلة مع مجتمع الكشتة").font(.caption).foregroundStyle(Color.white.opacity(0.7))
                        }
                        .padding(.top, 30)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            GlassTextField(icon: "tag.fill", placeholder: "اسم المكان (مثلاً: شعيب الحيسية)", text: $name)
                            GlassTextField(icon: "location.fill", placeholder: "المنطقة (مثلاً: العيينة)", text: $locationDesc)
                            
                            // Type Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("نوع المكان").font(.caption).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(types, id: \.self) { type in
                                            Button(action: { withAnimation { selectedType = type } }) {
                                                Text(type).font(.subheadline).padding(.horizontal, 16).padding(.vertical, 10)
                                                    .glassEffect(selectedType == type ? GlassStyle.regular.interactive().tint(Color.blue.opacity(0.4)) : GlassStyle.regular.interactive(), in: Capsule())
                                                    .foregroundStyle(Color.white)
                                            }.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            
                            // Image Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("صورة المكان").font(.caption).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal)
                                
                                if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable().scaledToFill().frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                        Button(action: { withAnimation { self.selectedItem = nil; self.selectedImageData = nil } }) {
                                            Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(Color.white.opacity(0.8)).shadow(radius: 5).padding(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                else if let selectedImageURL {
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: selectedImageURL)) { image in image.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.3) }
                                            .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                                        Button(action: { withAnimation { self.selectedImageURL = nil } }) {
                                            Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(Color.white.opacity(0.8)).shadow(radius: 5).padding(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                else {
                                    HStack(spacing: 15) {
                                        PhotosPicker(selection: $selectedItem, matching: .images) {
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo.badge.plus").font(.largeTitle)
                                                Text("رفع صورة").font(.caption).fontWeight(.bold)
                                            }
                                            .frame(width: 100, height: 100).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))).foregroundStyle(Color.white)
                                        }
                                        .onChange(of: selectedItem) {
                                            Task { if let data = try? await selectedItem?.loadTransferable(type: Data.self) { withAnimation { selectedImageData = data; selectedImageURL = nil } } }
                                        }
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(presetImages, id: \.self) { url in
                                                    Button(action: { withAnimation { selectedImageURL = url; selectedImageData = nil } }) {
                                                        AsyncImage(url: URL(string: url)) { image in image.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.3) }
                                                            .frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 16))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 24)).padding(.horizontal)
                        
                        // Submit
                        Button(action: {
                            isUploading = true
                            store.addSpot(name: name, location: locationDesc, type: selectedType, coordinate: coordinate, imageURL: selectedImageURL, imageData: selectedImageData)
                            
                            // Delay dismiss slightly if uploading
                            if selectedImageData != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    isUploading = false
                                    dismiss()
                                }
                            } else {
                                isUploading = false
                                dismiss()
                            }
                        }) {
                            HStack {
                                if isUploading { ProgressView().tint(.white) }
                                Text("نشر المكان").fontWeight(.bold)
                            }
                            .foregroundStyle(Color.white).frame(maxWidth: .infinity).padding().background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue).clipShape(Capsule())
                        }
                        .disabled(name.isEmpty || isUploading).padding(.horizontal).padding(.top, 20)
                    }
                }
            }
            .navigationTitle("").toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() }.foregroundStyle(Color.white) } }
        }
    }
}

struct GlassTextField: View { let icon: String, placeholder: String; @Binding var text: String; var body: some View { HStack { Image(systemName: icon).foregroundStyle(Color.white.opacity(0.6)); TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.white.opacity(0.4))).foregroundStyle(Color.white) }.padding().background(Color.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12)) } }

#Preview {
    AddSpotView()
}
