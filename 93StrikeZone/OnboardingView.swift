import SwiftUI

private let onboardingCompletedKey = "strikezone_hasSeenOnboarding"

enum OnboardingStorage {
    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey) }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @Binding var isCompleted: Bool

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.bowling",
            title: "Track Every Game",
            subtitle: "Log your frames, strikes and spares. See your score calculated automatically."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Stats & Goals",
            subtitle: "Follow your progress, set goals and unlock achievements as you improve."
        ),
        OnboardingPage(
            icon: "star.fill",
            title: "Your Bowling Hub",
            subtitle: "Manage players and places. Everything in one app, no account required."
        )
    ]

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            LinearGradient.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        onboardingPageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentPage)

                pageIndicator
                    .padding(.top, 24)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.strikeGold.opacity(0.25),
                                Color.strikeGold.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient.goldStroke, lineWidth: 2)
                    )
                    .shadow(color: Color.strikeGold.opacity(0.35), radius: 20, x: 0, y: 8)
                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient.goldAccent)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.strikeGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.strikeGold : Color.strikeGray.opacity(0.5))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation { currentPage += 1 }
            } else {
                completeOnboarding()
            }
        } label: {
            Text(currentPage < pages.count - 1 ? "Next" : "Get started")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.strikeBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldButton)
                .cornerRadius(14)
                .goldGlow()
        }
        .buttonStyle(.plain)
    }

    private func completeOnboarding() {
        OnboardingStorage.hasCompletedOnboarding = true
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
    }
}
