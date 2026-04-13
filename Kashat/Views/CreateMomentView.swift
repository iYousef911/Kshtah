//
//  CreateMomentView.swift
//  Kashat
//
//  Premium moment creation flow: live preview, location tag picker,
//  character counter, and an animated publish button.
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
    @State private var selectedSpotName: String? = nil
    @State private var isUploading = false
    @State private var showSpotPicker = false
    @State private var uploadDone = false

    private let maxCaption = 150

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Image Preview / Picker
                        imagePicker
                            .padding(.top, 8)

                        VStack(spacing: 20) {
                            captionField
                            locationTagRow
                            publishButton
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(settings.t("شارك لحظتك"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t("إلغاء")) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $showSpotPicker) {
                spotListPicker
            }
        }
    }

    // MARK: - Image Picker / Preview
    private var imagePicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .clipped()

                    // Edit overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Label(settings.t("تغيير الصورة"), systemImage: "pencil.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(12)
                        }
                    }
                    .frame(height: 420)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: 420)

                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "6C63FF"), Color(hex: "FC466B")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white)
                            }
                            Text(settings.t("اضغط لإضافة صورة من الكشتة"))
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(settings.t("اختر أجمل لحظة 📸"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    withAnimation { selectedImageData = data }
                }
            }
        }
    }

    // MARK: - Caption Field
    private var captionField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(settings.t("الوصف"), systemImage: "text.quote")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(caption.count)/\(maxCaption)")
                    .font(.caption2)
                    .foregroundStyle(caption.count > maxCaption - 20 ? .orange : .white.opacity(0.4))
            }

            TextField(settings.t("وش كانت الأجواء؟ وين كشتّ؟ 🏕️"), text: $caption, axis: .vertical)
                .font(.body)
                .padding(14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .tint(.white)
                .lineLimit(3...6)
                .onChange(of: caption) { _, new in
                    if new.count > maxCaption { caption = String(new.prefix(maxCaption)) }
                }
        }
        .padding(.top, 4)
    }

    // MARK: - Location Tag Row
    private var locationTagRow: some View {
        Button(action: { showSpotPicker = true }) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Color(hex: "6C63FF"))
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.t("وين هذي الكشتة؟"))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                    Text(selectedSpotName ?? settings.t("اضغط لتحديد المكان"))
                        .font(.subheadline)
                        .foregroundStyle(selectedSpotName != nil ? .white : .white.opacity(0.4))
                }

                Spacer()

                Image(systemName: selectedSpotName != nil ? "checkmark.circle.fill" : "chevron.left")
                    .foregroundStyle(selectedSpotName != nil ? .green : .white.opacity(0.3))
                    .font(.headline)
            }
            .padding(14)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Spots List Picker (sheet)
    private var spotListPicker: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0F2027"), Color(hex: "2C5364")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                List {
                    ForEach(store.spots) { spot in
                        Button(action: {
                            selectedSpotName = spot.name
                            showSpotPicker = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spot.name)
                                        .foregroundStyle(.white)
                                    Text(spot.location)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                if selectedSpotName == spot.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.07))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(settings.t("اختر المكان"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t("إلغاء")) { showSpotPicker = false }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t("بدون مكان")) {
                        selectedSpotName = nil
                        showSpotPicker = false
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Publish Button
    private var publishButton: some View {
        Button(action: uploadMoment) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "6C63FF"), Color(hex: "FC466B")],
                    startPoint: .leading, endPoint: .trailing
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "6C63FF").opacity(0.5), radius: 12, y: 6)

                if isUploading {
                    HStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text(settings.t("جاري النشر..."))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                } else if uploadDone {
                    Label(settings.t("تم النشر! ✅"), systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                } else {
                    Label(settings.t("انشر اليوميات"), systemImage: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 54)
        }
        .disabled(selectedImageData == nil || isUploading)
        .opacity(selectedImageData == nil ? 0.5 : 1.0)
        .padding(.top, 8)
    }

    // MARK: - Upload Logic
    private func uploadMoment() {
        guard let data = selectedImageData else { return }
        isUploading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        store.postGlobalMoment(
            imageData: data,
            caption: caption.isEmpty ? nil : caption,
            spotName: selectedSpotName
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            isUploading = false
            uploadDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
        }
    }
}
