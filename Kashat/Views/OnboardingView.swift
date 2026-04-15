//
//  OnboardingView.swift
//  Kashat
//
//  High-converting questionnaire-style onboarding
//  Built using the app-onboarding-questionnaire skill
//

import SwiftUI
import CoreLocation
import UserNotifications
import SuperwallKit

// MARK: - Onboarding Data Models

struct OnboardingSpot: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let type: String
    let icon: String
    let rating: Double
    let aiInsight: String
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    // ── Navigation ──
    @State private var currentScreen: Int = 0
    private let totalScreens: Int = 13

    // ── User answers ──
    @State private var selectedGoal: String = ""
    @State private var selectedPainPoints: Set<String> = []
    @State private var swipedCards: [String: Bool] = [:] // value: agreed?
    @State private var selectedTypes: Set<String> = []
    @State private var demoSelectedSpots: [OnboardingSpot] = []

    // ── Processing / demo ──
    @State private var processingProgress: Double = 0
    @State private var processingDone: Bool = false
    @State private var showValueDelivery: Bool = false

    // ── Permission ──
    private let locationManager = CLLocationManager()

    // ── Animations ──
    @State private var screenTransitionToken: Bool = false

    var body: some View {
        ZStack {
            // Background
            LiquidBackgroundView(color: backgroundColorForScreen(currentScreen))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentScreen)

            VStack(spacing: 0) {
                // Progress bar (hidden on welcome & paywall)
                if currentScreen > 0 && currentScreen < totalScreens - 1 {
                    progressBar
                        .padding(.top, 60)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }

                // Screen content
                ZStack {
                    switch currentScreen {
                    case 0:  WelcomeScreen(onStart: advance)
                    case 1:  GoalScreen(selectedGoal: $selectedGoal, onAdvance: advance)
                    case 2:  PainPointsScreen(selectedPainPoints: $selectedPainPoints, onAdvance: advance)
                    case 3:  SocialProofScreen(onAdvance: advance)
                    case 4:  TinderCardsScreen(swipedCards: $swipedCards, onAdvance: advance)
                    case 5:  SolutionScreen(selectedPainPoints: selectedPainPoints, onAdvance: advance)
                    case 6:  PreferenceScreen(selectedTypes: $selectedTypes, onAdvance: advance)
                    case 7:  LocationPrimeScreen(onAdvance: advance, locationManager: locationManager)
                    case 8:  NotificationPrimeScreen(onAdvance: advance)
                    case 9:  ProcessingScreen(progress: $processingProgress, onDone: { currentScreen = 10 })
                    case 10: DemoScreen(selectedTypes: selectedTypes, demoSelectedSpots: $demoSelectedSpots, onAdvance: advance)
                    case 11: ValueDeliveryScreen(demoSelectedSpots: demoSelectedSpots, selectedGoal: selectedGoal, selectedPainPoint: selectedPainPoints.first ?? "إضاعة الوقت", selectedTypes: Array(selectedTypes), onAdvance: advance)
                    case 12: PaywallScreen(onFinish: finishOnboarding)
                    default: EmptyView()
                    }
                }
                .id(currentScreen) // Force full rebuild on screen change
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let filled = max(0, min(1, Double(currentScreen) / Double(totalScreens - 2)))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * filled, height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentScreen)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentScreen += 1
        }
    }

    private func finishOnboarding() {
        withAnimation { hasSeenOnboarding = true }
    }

    // MARK: - Background color per screen

    private func backgroundColorForScreen(_ screen: Int) -> Color {
        switch screen {
        case 0: return .orange
        case 1: return Color(hue: 0.55, saturation: 0.7, brightness: 0.6)  // deep blue
        case 2: return Color(hue: 0.0, saturation: 0.7, brightness: 0.5)   // red
        case 3: return Color(hue: 0.75, saturation: 0.6, brightness: 0.5)  // purple
        case 4: return Color(hue: 0.6, saturation: 0.65, brightness: 0.5)  // indigo
        case 5: return Color(hue: 0.35, saturation: 0.7, brightness: 0.45) // green
        case 6: return Color(hue: 0.55, saturation: 0.6, brightness: 0.5)  // teal
        case 7: return Color(hue: 0.58, saturation: 0.7, brightness: 0.55) // sky blue
        case 8: return Color(hue: 0.08, saturation: 0.7, brightness: 0.55) // amber
        case 9: return Color(hue: 0.75, saturation: 0.55, brightness: 0.45)// dark indigo
        case 10: return Color(hue: 0.55, saturation: 0.7, brightness: 0.5) // ocean
        case 11: return Color(hue: 0.35, saturation: 0.65, brightness: 0.45)// forest
        case 12: return Color(hue: 0.58, saturation: 0.8, brightness: 0.4) // premium navy
        default: return .orange
        }
    }
}

// MARK: - Helpers

private struct OnboardingCTA: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(isDestructive ? Color.white.opacity(0.6) : Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isDestructive ? Color.clear : Color.white)
                .clipShape(Capsule())
                .overlay(isDestructive ? Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 1) : nil)
        }
    }
}

private struct OptionPill: View {
    let label: String
    let emoji: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { action() }) {
            HStack(spacing: 12) {
                Text(emoji).font(.title2)
                Text(label)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? Color.white.opacity(0.25)
                    : Color.white.opacity(0.08)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.white : Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Screen 1: WELCOME

private struct WelcomeScreen: View {
    let onStart: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero illustration
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .scaleEffect(appeared ? 1 : 0.5)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 280, height: 280)
                    .scaleEffect(appeared ? 1 : 0.5)

                Image(systemName: "tent.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.95, blue: 0.8), Color(red: 1, green: 0.75, blue: 0.3)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 30)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .offset(y: appeared ? 0 : 20)
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.65), value: appeared)
            .padding(.bottom, 48)

            // Copy
            VStack(spacing: 16) {
                Text("أحلى كشتة\nتنتظرك ⛺️")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)

                Text("اكتشف أجمل مواقع التخييم في المملكة،\nمع طقس حي، ومجتمع أصيل")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.easeOut(duration: 0.6).delay(0.35), value: appeared)
            }
            .padding(.bottom, 60)

            // CTA
            VStack(spacing: 16) {
                OnboardingCTA(title: "ابدأ رحلتي →", action: onStart)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)

                Text("مجاني تماماً للبدء")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.65), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 60)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Screen 2: GOAL QUESTION

private struct GoalScreen: View {
    @Binding var selectedGoal: String
    let onAdvance: () -> Void

    let goals: [(emoji: String, label: String, key: String)] = [
        ("🌌", "أشوف السماء والنجوم", "نجوم"),
        ("🏜️", "أتنفس هواء الصحراء", "صحراء"),
        ("👨‍👩‍👧‍👦", "رحلة مع العيلة", "عيلة"),
        ("🌊", "كشتة على البحر", "بحر"),
        ("🧗", "تجربة ومغامرة", "مغامرة"),
        ("😌", "هروب من الضغوط والهدوء", "هدوء")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("وش تبغى من رحلتك؟")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("اخترنا تجربة مناسبة لك تمامًا")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 32)
            .padding(.bottom, 32)
            .padding(.horizontal, 24)

            // Options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(goals, id: \.key) { goal in
                        OptionPill(
                            label: goal.label,
                            emoji: goal.emoji,
                            isSelected: selectedGoal == goal.key,
                            action: { selectedGoal = goal.key }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            // CTA (enabled only when selected)
            VStack(spacing: 0) {
                Divider().background(Color.white.opacity(0.1))
                Group {
                    if !selectedGoal.isEmpty {
                        OnboardingCTA(title: "هذا أنا! 👈", action: onAdvance)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        OnboardingCTA(title: "اختر هدفك أول", action: {})
                            .opacity(0.4)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .animation(.spring(response: 0.4), value: selectedGoal.isEmpty)
            }
        }
    }
}

// MARK: - Screen 3: PAIN POINTS

private struct PainPointsScreen: View {
    @Binding var selectedPainPoints: Set<String>
    let onAdvance: () -> Void

    let painPoints: [(emoji: String, label: String, key: String)] = [
        ("🗺️", "ما أعرف وين أروح وكيف أوصل", "توجيه"),
        ("⛅", "دايمًا أتفاجأ بسوء الطقس", "طقس"),
        ("👀", "الأماكن اللي أعرفها عادية وما فيها جديد", "تكرار"),
        ("🎒", "ما أعرف وش أحضر ووش أحتاج", "تجهيز"),
        ("📵", "أخاف أروح مكان مجهول لوحدي", "أمان"),
        ("💰", "الكشتة تكلف وايد وما عندي ميزانية", "تكلفة")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("إيش يوقفك عن\nالكشتة المثالية؟")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("اختر كل اللي ينطبق عليك")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(painPoints, id: \.key) { pain in
                        OptionPill(
                            label: pain.label,
                            emoji: pain.emoji,
                            isSelected: selectedPainPoints.contains(pain.key),
                            action: {
                                if selectedPainPoints.contains(pain.key) {
                                    selectedPainPoints.remove(pain.key)
                                } else {
                                    selectedPainPoints.insert(pain.key)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            VStack {
                OnboardingCTA(
                    title: selectedPainPoints.isEmpty ? "أنا ما عندي مشاكل 😎" : "فاهمين! →",
                    action: onAdvance
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Screen 4: SOCIAL PROOF

private struct SocialProofScreen: View {
    let onAdvance: () -> Void
    @State private var appeared = false

    let testimonials: [(name: String, tag: String, text: String, initials: String)] = [
        (
            "أبو فيصل العتيبي",
            "مغامر في عمر ٣٤",
            "وجدت وادي ما كنت أعرف بوجوده على بعد ساعة من الرياض. الإحداثيات صحيحة والطقس ما غشني.",
            "أ.ف"
        ),
        (
            "أمير الشمري",
            "أب لثلاثة أطفال",
            "خطط كشتتي العيلية في ١٠ دقائق. الأماكن آمنة ومناسبة للعيلة، والتطبيق عطاني قائمة التجهيز كاملة.",
            "أ.ش"
        ),
        (
            "سلمى الحربي",
            "محبة النجوم",
            "أخيرًا لقيت مكان بعيد عن أضواء المدينة. مقياس بورتل ٢! صورت السماء أجمل صورة في حياتي.",
            "س.ح"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("آلاف الكشاتة\nوثقوا فينا 🤝")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                    }
                    Text("4.8 من 47,000 كشات")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(testimonials.enumerated()), id: \.offset) { index, t in
                        TestimonialCard(
                            name: t.name,
                            tag: t.tag,
                            text: t.text,
                            initials: t.initials
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.15), value: appeared)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            OnboardingCTA(title: "واضح، خلنا نكمل →", action: onAdvance)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
        }
        .onAppear { appeared = true }
    }
}

private struct TestimonialCard: View {
    let name: String
    let tag: String
    let text: String
    let initials: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 44, height: 44)
                    .overlay(Text(initials).font(.caption.bold()).foregroundStyle(.white))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.subheadline.bold()).foregroundStyle(.white)
                    Text(tag)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption2)
                    }
                }
            }
            Text("\"" + text + "\""  )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Screen 5: TINDER SWIPE CARDS

private struct TinderCardsScreen: View {
    @Binding var swipedCards: [String: Bool]
    let onAdvance: () -> Void

    let statements: [(key: String, text: String)] = [
        ("boring", "\"دايمًا أروح نفس المكان لأني ما أعرف أماكن ثانية\""),
        ("weather", "\"فاجأني الطقس أكثر من مرة وخربت الكشتة\""),
        ("gear", "\"ما أعرف وش أحضر، دايمًا ينقصني شي في البر\""),
        ("alone", "\"أبغى أروح البر بس ما أحد يشاركني\"")
    ]

    @State private var currentCardIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var allDone: Bool = false

    private var currentStatement: (key: String, text: String)? {
        guard currentCardIndex < statements.count else { return nil }
        return statements[currentCardIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("وش منهم يوصفك؟")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("ازيح يمين إذا يوصفك ✓  •  ازيح شمال إذا لا ✗")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.bottom, 32)
            .padding(.horizontal, 24)

            Spacer()

            ZStack {
                if allDone {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce)
                        Text("فاهمينك تمامًا 💪")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if let card = currentStatement {
                    // Background cards
                    ForEach(Array(statements.enumerated().reversed()), id: \.offset) { index, stmt in
                        if index > currentCardIndex {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 200)
                                .scaleEffect(1.0 - Double(index - currentCardIndex) * 0.05)
                                .offset(y: Double(index - currentCardIndex) * -10)
                        }
                    }

                    // Active card
                    TinderCard(
                        text: card.text,
                        dragOffset: $dragOffset,
                        onSwiped: { agreed in
                            withAnimation(.spring(response: 0.4)) {
                                swipedCards[card.key] = agreed
                                dragOffset = .zero
                                if currentCardIndex < statements.count - 1 {
                                    currentCardIndex += 1
                                } else {
                                    allDone = true
                                }
                            }
                        }
                    )
                }
            }
            .frame(height: 260)
            .padding(.horizontal, 32)
            .animation(.spring(response: 0.5), value: currentCardIndex)
            .animation(.easeInOut, value: allDone)

            Spacer()

            if allDone {
                OnboardingCTA(title: "كشتات فاهمتك ✓", action: onAdvance)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<statements.count, id: \.self) { i in
                        Circle()
                            .fill(i < currentCardIndex ? Color.white : (i == currentCardIndex ? Color.white : Color.white.opacity(0.25)))
                            .frame(width: i == currentCardIndex ? 10 : 7, height: i == currentCardIndex ? 10 : 7)
                            .animation(.spring(), value: currentCardIndex)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

private struct TinderCard: View {
    let text: String
    @Binding var dragOffset: CGSize
    let onSwiped: (Bool) -> Void

    @State private var localDrag: CGSize = .zero

    // In RTL layout, DragGesture reports NEGATIVE width for a physical right swipe.
    // physicalX normalises this: positive = physically right, negative = physically left.
    private var physicalX: Double { -Double(localDrag.width) }

    private var rotation: Angle    { .degrees(physicalX / 20) }
    private var agreeOpacity: Double    { max(0, min(1,  physicalX / 80)) } // right swipe → agree
    private var disagreeOpacity: Double { max(0, min(1, -physicalX / 80)) } // left swipe  → disagree

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))

            VStack(spacing: 20) {
                Image(systemName: "quote.bubble.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.4))

                Text(text)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            .padding(24)

            // Agree overlay — appears when swiping physically right
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.green.opacity(0.3))
                .overlay(
                    Text("أوافق ✓")
                        .font(.title.bold())
                        .foregroundStyle(.green)
                )
                .opacity(agreeOpacity)

            // Disagree overlay — appears when swiping physically left
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.red.opacity(0.3))
                .overlay(
                    Text("لا ✗")
                        .font(.title.bold())
                        .foregroundStyle(.red)
                )
                .opacity(disagreeOpacity)
        }
        .frame(height: 200)
        .rotationEffect(rotation)
        // physicalX is positive-right; in RTL offset(x:) also needs inversion so the card
        // physically follows the finger correctly.
        .offset(x: -physicalX, y: localDrag.height * 0.2)
        .gesture(
            DragGesture()
                .onChanged { value in
                    localDrag = value.translation
                }
                .onEnded { value in
                    // physicalWidth > 0 = dragged physically right = agree
                    let physicalWidth = -value.translation.width
                    if abs(physicalWidth) > 100 {
                        let agreed = physicalWidth > 0
                        withAnimation(.easeOut(duration: 0.3)) {
                            // Move card off-screen in the physical drag direction (RTL: negate)
                            localDrag = CGSize(width: agreed ? -400 : 400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            localDrag = .zero
                            onSwiped(agreed)
                        }
                    } else {
                        withAnimation(.spring()) { localDrag = .zero }
                    }
                }
        )
    }
}


// MARK: - Screen 6: PERSONALISED SOLUTION

private struct SolutionScreen: View {
    let selectedPainPoints: Set<String>
    let onAdvance: () -> Void
    @State private var appeared = false

    struct SolutionItem {
        let key: String
        let painIcon: String
        let pain: String
        let solutionIcon: String
        let solution: String
    }

    let allSolutions: [SolutionItem] = [
        SolutionItem(key: "توجيه", painIcon: "🗺️", pain: "مش عارف وين أروح",
                     solutionIcon: "mappin.and.ellipse", solution: "+500 موقع بإحداثيات دقيقة وتوجيه مباشر"),
        SolutionItem(key: "طقس", painIcon: "⛅", pain: "الطقس يفسد الكشتة",
                     solutionIcon: "cloud.sun.fill", solution: "طقس حي وتنبيهات قبل رحلتك بـ 24 ساعة"),
        SolutionItem(key: "تكرار", painIcon: "👀", pain: "نفس الأماكن الممله",
                     solutionIcon: "sparkles", solution: "أماكن سرية يشاركها المجتمع باستمرار"),
        SolutionItem(key: "تجهيز", painIcon: "🎒", pain: "ما أعرف وش أحضر",
                     solutionIcon: "checklist", solution: "قوائم تجهيز جاهزة لكل نوع كشتة"),
        SolutionItem(key: "أمان", painIcon: "📵", pain: "أخاف أروح لوحدي",
                     solutionIcon: "person.3.fill", solution: "مجتمع نشط وقوافل جماعية (PRO)"),
        SolutionItem(key: "تكلفة", painIcon: "💰", pain: "الكشتة تكلف وايد",
                     solutionIcon: "tag.fill", solution: "مقارنة الأماكن وإيجاد أرخص الخيارات")
    ]

    var displayedSolutions: [SolutionItem] {
        let selected = allSolutions.filter { selectedPainPoints.contains($0.key) }
        if selected.isEmpty {
            return Array(allSolutions.prefix(4))
        }
        return Array(selected.prefix(4))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("كشتات عندها\nالحل 🎯")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("بناءً على اللي قلته، هذا اللي نقدر نسوّيه")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Array(displayedSolutions.enumerated()), id: \.offset) { index, item in
                        SolutionRow(item: item)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : -30)
                            .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.12), value: appeared)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            OnboardingCTA(title: "ممتاز، خلنا نكمل →", action: onAdvance)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
        }
        .onAppear { appeared = true }
    }
}

private struct SolutionRow: View {
    let item: SolutionScreen.SolutionItem

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: item.solutionIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.painIcon + " " + item.pain)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Text(item.solution)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Screen 7: PREFERENCE GRID

private struct PreferenceScreen: View {
    @Binding var selectedTypes: Set<String>
    let onAdvance: () -> Void

    let types: [(emoji: String, label: String, key: String)] = [
        ("⛺️", "مخيمات", "مخيمات"),
        ("🏜️", "كثبان رملية", "كثبان"),
        ("🌊", "وادي وأنهار", "وادي"),
        ("🏔️", "جبال وهضاب", "جبل"),
        ("🌅", "شواطئ", "شاطئ"),
        ("🌿", "روضات وحدائق", "روضة")
    ]

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("وش نوع البر\nاللي تحبه؟ 🌄")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("اختر كل ما يناسبك (اختيار متعدد)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(types, id: \.key) { type in
                        PreferenceCell(
                            emoji: type.emoji,
                            label: type.label,
                            isSelected: selectedTypes.contains(type.key),
                            action: {
                                if selectedTypes.contains(type.key) {
                                    selectedTypes.remove(type.key)
                                } else {
                                    selectedTypes.insert(type.key)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            OnboardingCTA(
                title: selectedTypes.isEmpty ? "فاجئني بكل شي!" : "ممتاز، هذا أنا! ✓",
                action: onAdvance
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .animation(.spring(response: 0.4), value: selectedTypes.isEmpty)
        }
    }
}

private struct PreferenceCell: View {
    let emoji: String
    let label: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { action() }) {
            VStack(spacing: 10) {
                Text(emoji).font(.system(size: 40))
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? Color.white : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Screen 8: LOCATION PRIME

private struct LocationPrimeScreen: View {
    let onAdvance: () -> Void
    let locationManager: CLLocationManager
    @State private var requesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero
            ZStack {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 180, height: 180)
                Circle().fill(Color.white.opacity(0.05)).frame(width: 240, height: 240)
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(Color.white.gradient)
                    .symbolEffect(.pulse)
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("خلنا نوريك ما\nحولك من أماكن 🗺️")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    BulletRow(icon: "mappin.circle.fill", text: "أقرب الكشتات لموقعك الآن")
                    BulletRow(icon: "cloud.sun.fill", text: "طقس دقيق لمنطقتك")
                    BulletRow(icon: "person.3.fill", text: "قوافل قريبة منك تستطيع الانضمام إليها")
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                OnboardingCTA(title: "تفعيل الموقع 📍", action: {
                    requesting = true
                    LocationManager.shared.requestLocationPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { onAdvance() }
                })

                Button("ليس الآن") { onAdvance() }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct BulletRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(.white).font(.title3).frame(width: 28)
            Text(text).font(.subheadline).foregroundStyle(.white.opacity(0.9))
        }
    }
}

// MARK: - Screen 9: NOTIFICATION PRIME

private struct NotificationPrimeScreen: View {
    let onAdvance: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 180, height: 180)
                Circle().fill(Color.white.opacity(0.05)).frame(width: 240, height: 240)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(Color.white.gradient)
                    .symbolEffect(.bounce)
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("ما تفوتك كشتة!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    BulletRow(icon: "cloud.bolt.rain.fill", text: "تحذير طقس قبل رحلتك بـ 24 ساعة")
                    BulletRow(icon: "star.fill", text: "مواقع جديدة قريبة منك تُضاف")
                    BulletRow(icon: "person.badge.plus.fill", text: "رد على تعليقاتك ومراجعاتك")
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                OnboardingCTA(title: "تفعيل الإشعارات 🔔", action: {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                        DispatchQueue.main.async { onAdvance() }
                    }
                })
                Button("ليس الآن") { onAdvance() }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 10: PROCESSING MOMENT

private struct ProcessingScreen: View {
    @Binding var progress: Double
    let onDone: () -> Void

    @State private var currentStep = 0
    @State private var pulsing = false

    let steps = [
        "نحلل تفضيلاتك...",
        "نختار أجمل المواقع...",
        "نجهز عزبتك التجريبية...",
        "كل شي جاهز! 🎉"
    ]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulsing ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsing)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                Image(systemName: "tent.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            VStack(spacing: 12) {
                Text("نجهز عزبتك...")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(steps[min(currentStep, steps.count - 1)])
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .id(currentStep) // Animate text change
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }

            Spacer()
        }
        .onAppear {
            pulsing = true
            animateProgress()
        }
    }

    private func animateProgress() {
        let stepDuration: Double = 0.5
        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation { progress = Double(i + 1) / Double(steps.count) }
                currentStep = i
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(steps.count) + 0.3) {
            onDone()
        }
    }
}

// MARK: - Screen 11: APP DEMO

private struct DemoScreen: View {
    let selectedTypes: Set<String>
    @Binding var demoSelectedSpots: [OnboardingSpot]
    let onAdvance: () -> Void

    @State private var selectionPulse: UUID? = nil

    // Curated demo spots
    private let allDemoSpots: [OnboardingSpot] = [
        OnboardingSpot(name: "نفود الثويرات", location: "الزلفي", type: "كثبان", icon: "wind", rating: 4.9, aiInsight: "أفضل وقت: ديسمبر - فبراير"),
        OnboardingSpot(name: "وادي لجب", location: "جازان", type: "وادي", icon: "water.waves", rating: 4.7, aiInsight: "مياه نقية ومناخ رائع"),
        OnboardingSpot(name: "جبل طويق", location: "القدية", type: "جبل", icon: "mountain.2.fill", rating: 4.6, aiInsight: "إطلالة بانورامية مذهلة"),
        OnboardingSpot(name: "شاطئ أبحر", location: "جدة", type: "شاطئ", icon: "sun.max.fill", rating: 4.8, aiInsight: "مثالي للعائلات"),
        OnboardingSpot(name: "روضة خريم", location: "الرياض", type: "مخيمات", icon: "tent.fill", rating: 4.8, aiInsight: "قريب وسهل الوصول"),
        OnboardingSpot(name: "رمال العالية", location: "الرياض", type: "كثبان", icon: "wind", rating: 4.5, aiInsight: "أقرب كثبان للرياض"),
        OnboardingSpot(name: "وادي حنيفة", location: "الرياض", type: "وادي", icon: "water.waves", rating: 4.4, aiInsight: "مسارات مشي رائعة"),
        OnboardingSpot(name: "جبال الحجاز", location: "الطائف", type: "جبل", icon: "mountain.2.fill", rating: 4.7, aiInsight: "هواء بارد وطبيعة خلابة"),
        OnboardingSpot(name: "شاطئ الفناتير", location: "الجبيل", type: "شاطئ", icon: "sun.max.fill", rating: 4.6, aiInsight: "مياه هادئة وصافية"),
        OnboardingSpot(name: "روضة قاع القصب", location: "الخرج", type: "روضة", icon: "leaf.fill", rating: 4.5, aiInsight: "طبيعة خضراء جميلة")
    ]

    private var filteredSpots: [OnboardingSpot] {
        let preferred = allDemoSpots.filter { selectedTypes.contains($0.type) }
        if preferred.count >= 4 { return Array(preferred.prefix(6)) }
        return Array(allDemoSpots.prefix(6))
    }

    private var remaining: Int { max(0, 3 - demoSelectedSpots.count) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text("اختر ٣ أماكن\nلعزبتك! 🗺️")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if remaining > 0 {
                    Text("باقي \(remaining) \(remaining == 1 ? "مكان" : "أماكن")")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .contentTransition(.numericText())
                        .animation(.spring(), value: remaining)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("العزبة جاهزة!")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredSpots) { spot in
                        DemoSpotCell(
                            spot: spot,
                            isSelected: demoSelectedSpots.contains(where: { $0.id == spot.id }),
                            canSelect: demoSelectedSpots.count < 3 || demoSelectedSpots.contains(where: { $0.id == spot.id }),
                            action: {
                                if let idx = demoSelectedSpots.firstIndex(where: { $0.id == spot.id }) {
                                    withAnimation(.spring(response: 0.3)) { demoSelectedSpots.remove(at: idx) }
                                } else if demoSelectedSpots.count < 3 {
                                    withAnimation(.spring(response: 0.3)) { demoSelectedSpots.append(spot) }
                                    let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            // CTA
            Group {
                if demoSelectedSpots.count == 3 {
                    OnboardingCTA(title: "شف عزبتك! 🎉", action: onAdvance)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    OnboardingCTA(title: "اختر \(remaining) أماكن أكثر", action: {})
                        .opacity(0.4)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .animation(.spring(response: 0.4), value: demoSelectedSpots.count)
        }
    }
}

private struct DemoSpotCell: View {
    let spot: OnboardingSpot
    let isSelected: Bool
    let canSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                            .frame(height: 70)
                        Image(systemName: spot.icon)
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .background(Circle().fill(Color.white))
                            .offset(x: 6, y: -6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(spacing: 2) {
                    Text(spot.name)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(spot.location)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                        Text(String(format: "%.1f", spot.rating)).font(.caption2).foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isSelected ? Color.white : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
            )
            .opacity((!canSelect && !isSelected) ? 0.4 : 1.0)
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Screen 12: VALUE DELIVERY

private struct ValueDeliveryScreen: View {
    let demoSelectedSpots: [OnboardingSpot]
    let selectedGoal: String
    let selectedPainPoint: String
    let selectedTypes: [String]
    let onAdvance: () -> Void

    @State private var appeared = false
    @State private var showPlan = false
    @State private var dynamicAIInsight: String = "جاري التخطيط الذكي مع كشّات... 🌟"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("🎉")
                        .font(.system(size: 70))
                        .scaleEffect(appeared ? 1 : 0.1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appeared)

                    Text("عزبتك جاهزة!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                    Text("هذا خطط كشتتك بناءً على اختياراتك")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)
                }
                .padding(.top, 48)

                // Trip plan card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("خطة كشتتك", systemImage: "doc.text.fill")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        if !selectedGoal.isEmpty {
                            Text("🎯 \(selectedGoal)")
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    Divider().background(Color.white.opacity(0.2))

                    ForEach(Array(demoSelectedSpots.enumerated()), id: \.offset) { index, spot in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color.white.opacity(0.15)).frame(width: 40, height: 40)
                                Text("\(index + 1)").font(.headline.bold()).foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spot.name).font(.subheadline.bold()).foregroundStyle(.white)
                                Text(spot.location + " • " + spot.aiInsight)
                                    .font(.caption).foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                                Text(String(format: "%.1f", spot.rating)).font(.caption).foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .opacity(showPlan ? 1 : 0)
                        .offset(x: showPlan ? 0 : -20)
                        .animation(.easeOut(duration: 0.4).delay(0.6 + Double(index) * 0.15), value: showPlan)
                    }

                    Divider().background(Color.white.opacity(0.2))
                    // AI insight footer
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles").foregroundStyle(.yellow)
                        Text(dynamicAIInsight)
                            .font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)

                // Share button
                ShareLink(
                    item: buildShareText(),
                    preview: SharePreview("خطة كشتتي مع كشتات", image: Image(systemName: "tent.fill"))
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                        Text("شارك خطة عزبتك")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.9), value: appeared)

                // Main CTA
                VStack(spacing: 10) {
                    OnboardingCTA(title: "احفظ العزبة وانضم مجانًا →", action: onAdvance)

                    Text("انضم لـ 47,000+ كشات")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(1.0), value: appeared)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            // Fetch real Cloudflare AI payload based on features
            let insight = await AIService.shared.generateOnboardingInsight(
                goal: selectedGoal,
                painPoint: selectedPainPoint,
                features: selectedTypes
            )
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.dynamicAIInsight = "الذكاء الاصطناعي: " + insight
                }
            }
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showPlan = true }
        }
    }

    private func buildShareText() -> String {
        let names = demoSelectedSpots.map { "• \($0.name) (\($0.location))" }.joined(separator: "\n")
        return "خطة كشتتي القادمة 🏕️\n\n\(names)\n\nاكتشف أجمل مواقع التخييم بالمملكة مع تطبيق كشتات!"
    }
}

// MARK: - Screen 13: PAYWALL (Pre-sell — Superwall presents real pricing)

private struct PaywallScreen: View {
    let onFinish: () -> Void
    @State private var appeared = false

    let features: [(icon: String, title: String, desc: String)] = [
        ("sparkles", "خبير الكشتات الذكي", "خطط رحلتك كاملة بالذكاء الاصطناعي"),
        ("car.2.fill", "وضع القافلة", "تتبع موقع أصدقائك في البر"),
        ("moon.stars.fill", "خريطة بورتل للنجوم", "اكتشف أفضل مواقع مراقبة النجوم"),
        ("lock.open.fill", "مواقع PRO حصرية", "أماكن سرية نشاركها مع المشتركين فقط"),
        ("cloud.fill", "تحذيرات طقس ذكية", "تنبيهات مخصصة قبل رحلتك")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.08)).frame(width: 120, height: 120)
                        Image(systemName: "tent.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1, green: 0.95, blue: 0.7), Color(red: 1, green: 0.75, blue: 0.3)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

                    VStack(spacing: 8) {
                        Text("كشتات PRO")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("رفيقك الذكي في البر 🌟")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
                }
                .padding(.top, 48)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)

                // Testimonial
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(Text("خ.ع").font(.caption.bold()).foregroundStyle(.white))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { _ in Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow) }
                        }
                        Text("\"PRO غير تجربتي الكاملة. خاصية القافلة وحدها تستاهل.\"")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)
                .padding(.bottom, 20)

                // Features list
                VStack(spacing: 12) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(.yellow)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title).font(.subheadline.bold()).foregroundStyle(.white)
                                Text(feature.desc).font(.caption).foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "checkmark").foregroundStyle(.green).font(.subheadline.bold())
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4 + Double(index) * 0.08), value: appeared)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // No hardcoded pricing here — Superwall shows real prices from your dashboard

                // CTAs — gold button opens Superwall's native paywall with your real prices
                VStack(spacing: 14) {
                    Button(action: presentSuperwallPaywall) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                            Text("شاهد الخطط والأسعار →")
                        }
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.95, blue: 0.7), Color(red: 1, green: 0.8, blue: 0.4)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }

                    Button("لا شكرًا، سأجرب المجاني") { onFinish() }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))

                    Text("الأسعار والتفاصيل ستظهر في الخطوة التالية.\nيمكنك الإلغاء في أي وقت.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.9), value: appeared)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { appeared = true }
    }

    // MARK: - Superwall Integration
    // Opens Superwall's own paywall UI with your real prices + trial from your dashboard.
    // Requires "onboarding_paywall" to be a registered placement in your Superwall dashboard.
    // If you haven't created it yet, log in at superwall.com → Placements → New Placement.
    // onFinish() fires when user subscribes or hits Close — so onboarding always completes.
    private func presentSuperwallPaywall() {
        let handler = PaywallPresentationHandler()
        handler.onDismiss { _, _ in
            DispatchQueue.main.async { onFinish() }
        }
        handler.onError { _ in
            DispatchQueue.main.async { onFinish() }
        }
        Superwall.shared.register(placement: "campaign_trigger", handler: handler)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(SettingsManager())
        .environmentObject(ThemeManager())
        .environmentObject(AppDataStore())
}
