//
//  GIFPickerView.swift
//  Kashat
//
//  GIF picker sheet using Giphy API.
//

import SwiftUI

struct GIFPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var gifs: [GiphyItem] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var task: Task<Void, Never>?
    @State private var errorMessage: String?
    
    var onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.6))
                        TextField(NSLocalizedString("ابحث عن GIF...", comment: ""), text: $searchText)
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .onSubmit { loadGifs() }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Text(NSLocalizedString("يرجى إضافة مفتاح Giphy API في GiphyService.swift", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else if gifs.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("لا توجد صور متحركة", comment: ""))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(NSLocalizedString("جرب البحث بكلمات مختلفة", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(gifs) { gif in
                                    GIFCell(url: gif.previewURL) {
                                        onSelect(gif.url)
                                        dismiss()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("GIF", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("إلغاء", comment: "")) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .task {
                loadGifs()
            }
            .onChange(of: searchText) { _, newValue in
                task?.cancel()
                task = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run { loadGifs() }
                }
            }
        }
    }
    
    private func loadGifs() {
        isLoading = true
        Task {
            do {
                let items: [GiphyItem]
                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    print("📊 Loading trending GIFs...")
                    items = try await GiphyService.shared.trending()
                } else {
                    print("🔍 Searching GIFs for: '\(searchText)'")
                    items = try await GiphyService.shared.search(query: searchText)
                }
                print("✅ Loaded \(items.count) GIFs")
                await MainActor.run {
                    gifs = items
                    isLoading = false
                }
            } catch {
                print("❌ Error loading GIFs: \(error.localizedDescription)")
                print("❌ Full error: \(error)")
                await MainActor.run {
                    gifs = []
                    isLoading = false
                    // Show user-friendly error message
                    if let nsError = error as NSError? {
                        if nsError.code == 403 || nsError.code == 401 {
                            errorMessage = NSLocalizedString("مفتاح API غير صالح. يرجى إضافة مفتاح Giphy API الخاص بك", comment: "")
                        } else if nsError.code == 429 {
                            errorMessage = NSLocalizedString("تم تجاوز حد الطلبات. يرجى المحاولة لاحقاً", comment: "")
                        } else {
                            errorMessage = String(format: NSLocalizedString("خطأ في تحميل GIFs: %@", comment: ""), error.localizedDescription)
                        }
                    } else {
                        errorMessage = String(format: NSLocalizedString("خطأ في تحميل GIFs: %@", comment: ""), error.localizedDescription)
                    }
                }
            }
        }
    }
}

private struct GIFCell: View {
    let url: String
    let onTap: () -> Void
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Color.white.opacity(0.1)
                    .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.5)))
            case .empty:
                Color.white.opacity(0.1)
                    .overlay(ProgressView().tint(.white))
            @unknown default:
                Color.white.opacity(0.1)
            }
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
    }
}
