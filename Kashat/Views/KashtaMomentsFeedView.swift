//
//  KashtaMomentsFeedView.swift
//  Kashat
//

import SwiftUI

// MARK: - Main Feed View
struct KashtaMomentsFeedView: View {
    @EnvironmentObject var store: AppDataStore
    @EnvironmentObject var settings: SettingsManager
    @State private var showCreateMoment = false

    // Read safe area insets from UIKit — reliable on all devices
    private var safeBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
    private var safeTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }
    // Total clearance needed at the bottom: safe area + tab bar height
    private var bottomClear: CGFloat { safeBottom + 49 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if store.globalMoments.isEmpty {
                emptyState
            } else {
                // Paged scroll — each card uses containerRelativeFrame
                // which correctly gives the full visible height (behind tab bar)
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.globalMoments.enumerated()), id: \.element.id) { idx, moment in
                            MomentCardView(
                                moment: moment,
                                index: idx,
                                total: store.globalMoments.count,
                                bottomClear: bottomClear,
                                safeTop: safeTop
                            )
                            .containerRelativeFrame(.vertical) // fills the tab view height
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
                .refreshable { store.fetchGlobalMoments() }
            }

            // Header — always on top
            if !store.globalMoments.isEmpty {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.t("يوميات الكشتة"))
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                            Text("\(store.globalMoments.count) \(settings.t("لحظة"))")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, safeTop + 4)
                    .padding(.bottom, 20)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.7), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }

            // Create button — pinned above tab bar
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showCreateMoment = true }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "6C63FF"), Color(hex: "FC466B")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 52, height: 52)
                                .shadow(color: Color(hex: "6C63FF").opacity(0.6), radius: 12, y: 4)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, bottomClear + 16)
                }
            }
        }
        .sheet(isPresented: $showCreateMoment) {
            CreateMomentView()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .task {
            if store.globalMoments.isEmpty { store.fetchGlobalMoments() }
        }
        .trackScreen(name: "Moments")
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F2027"), Color(hex: "2C5364")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "camera.macro.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "6C63FF"), Color(hex: "FC466B")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.breathe)

                VStack(spacing: 8) {
                    Text(settings.t("لا توجد يوميات حتى الآن"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(settings.t("كن أول من يشارك لحظة كشتته! 🏕️"))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                Button(action: { showCreateMoment = true }) {
                    Label(settings.t("شارك كشتتك"), systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "6C63FF"), Color(hex: "FC466B")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "6C63FF").opacity(0.5), radius: 10, y: 5)
                }
            }
            .padding()
        }
    }
}

// MARK: - Individual Moment Card
struct MomentCardView: View {
    let moment: SpotMoment
    let index: Int
    let total: Int
    let bottomClear: CGFloat
    let safeTop: CGFloat

    @EnvironmentObject var store: AppDataStore
    @State private var isLiked = false
    @State private var showHeartBurst = false
    @State private var showFullCaption = false

    private var currentUserId: String? { store.userProfile?.id }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Full-bleed background image
            GeometryReader { geo in
                AsyncImage(url: URL(string: moment.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Color(hex: "1a1a2e")
                            .overlay(ProgressView().tint(.white).scaleEffect(1.3))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    case .failure:
                        Color(hex: "1a1a2e")
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white.opacity(0.2))
                            )
                    @unknown default:
                        Color.black
                    }
                }
            }
            .ignoresSafeArea()

            // 2. Gradient scrim — covers the bottom third
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.5), location: 0.3),
                        .init(color: .black.opacity(0.9), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)
            }
            .ignoresSafeArea()

            // 3. Heart burst (double-tap feedback)
            if showHeartBurst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .white.opacity(0.3), radius: 20)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 4. Bottom HUD — sits above the tab bar
            HStack(alignment: .bottom, spacing: 0) {

                // Left side: avatar, name, caption, time
                VStack(alignment: .leading, spacing: 10) {
                    // Avatar + name row
                    HStack(spacing: 10) {
                        avatarView
                        VStack(alignment: .leading, spacing: 2) {
                            Text(moment.userName)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                            if let spot = moment.spotName, !spot.isEmpty {
                                Label(spot, systemImage: "mappin.and.ellipse")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white.opacity(0.85))
                                    .shadow(color: .black.opacity(0.4), radius: 3)
                            }
                        }
                    }

                    // Caption
                    if let caption = moment.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(showFullCaption ? nil : 2)
                            .multilineTextAlignment(.leading)
                            .shadow(color: .black.opacity(0.6), radius: 4)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFullCaption.toggle()
                                }
                            }
                    }

                    // Timestamp
                    Text(moment.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.leading, 16)
                // Constrain so right rail is never squeezed off-screen
                .frame(maxWidth: UIScreen.main.bounds.width * 0.65, alignment: .leading)

                Spacer()

                // Right side: action buttons rail
                VStack(spacing: 24) {
                    // Like
                    Button(action: handleLike) {
                        VStack(spacing: 5) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(isLiked ? Color(hex: "FC466B") : .white)
                                .scaleEffect(isLiked ? 1.1 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isLiked)
                                .shadow(color: isLiked ? Color(hex: "FC466B").opacity(0.8) : .black.opacity(0.4), radius: 6)

                            Text(moment.likesCount > 0 ? "\(moment.likesCount)" : "")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .frame(height: 14)
                        }
                    }

                    // Share
                    Button(action: shareSheet) {
                        VStack(spacing: 5) {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 4)
                            Text("نشر")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    // Bookmark placeholder
                    Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred() }) {
                        VStack(spacing: 5) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 4)
                            Text("حفظ")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.trailing, 16)
            }
            // KEY FIX: bottomClear is safeBottom + tabBarHeight.
            // This pads the HUD up from the BOTTOM EDGE of the card frame
            // so it clears the tab bar exactly.
            .padding(.bottom, bottomClear + 16)
        }
        // Double-tap anywhere on the card to like
        .onTapGesture(count: 2) { handleDoubleTap() }
        .onAppear {
            isLiked = moment.likedByUserIds.contains(currentUserId ?? "")
        }
    }

    // MARK: - Avatar
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "6C63FF"), Color(hex: "FC466B")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 44, height: 44)

            if let urlStr = moment.userProfileImageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())
            } else {
                Text(String(moment.userName.prefix(1)))
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
        }
        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1.5))
    }

    // MARK: - Progress Pills (right side, upper)
    private var progressPills: some View {
        VStack(spacing: 3) {
            ForEach(0..<min(total, 10), id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 3, height: i == index ? 18 : 6)
                    .animation(.spring(response: 0.25), value: index)
            }
        }
    }

    // MARK: - Interactions
    private func handleLike() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { isLiked.toggle() }
        store.toggleLikeMoment(moment)
    }

    private func handleDoubleTap() {
        if !isLiked {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation { isLiked = true }
            store.toggleLikeMoment(moment)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            showHeartBurst = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.25)) {
                showHeartBurst = false
            }
        }
    }

    private func shareSheet() {
        guard let url = URL(string: moment.imageURL) else { return }
        let text = moment.caption ?? "شوف هالكشتة 🏕️"
        let vc = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(vc, animated: true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
