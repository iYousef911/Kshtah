//
//  KashtaMomentsFeedView.swift
//  Kashat
//

import SwiftUI

struct KashtaMomentsFeedView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @State private var showCreateMoment = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                if store.globalMoments.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.macro.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.white.opacity(0.3))
                        
                        Text(settings.t("لا توجد يوميات حتى الآن"))
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text(settings.t("كن أول من يشارك كشتته! 🏕️"))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(store.globalMoments) { moment in
                                MomentCardView(moment: moment)
                                    .containerRelativeFrame(.vertical) // New iOS 17 API for full-screen scrolling
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging) // Snap to cards! iOS 17 performant scrolling
                    .ignoresSafeArea(.all, edges: .top)
                }
                
                // Floating Action Button to post new moment
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showCreateMoment = true }) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(Circle())
                                .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(settings.t("يوميات الكشتة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCreateMoment) {
                CreateMomentView()
                    .environmentObject(store)
                    .environmentObject(settings)
            }
        }
    }
}

struct MomentCardView: View {
    let moment: SpotMoment
    @EnvironmentObject var store: AppDataStore
    
    var body: some View {
        ZStack {
            // Background Image
            AsyncImage(url: URL(string: moment.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView().tint(.white))
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                case .failure:
                    Rectangle().fill(Color.gray.opacity(0.2))
                        .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.5)))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Linear Gradient to make text readable
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6), .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
            }
            
            // Bottom Info Overlay
            VStack(alignment: .leading) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        // User info
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                            Text(moment.userName)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        
                        // Caption
                        if let caption = moment.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        
                        Text(moment.timeAgo)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Interaction Buttons stack
                    VStack(spacing: 20) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            // Future: Heart interaction
                        }) {
                            VStack {
                                Image(systemName: "heart.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                Text("إعجاب")
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            // Future: Share
                        }) {
                            VStack {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                Text("مشاركة")
                                    .font(.caption)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 40) // Space for TabBar
            }
        }
    }
}
