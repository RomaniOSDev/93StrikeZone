import SwiftUI
import StoreKit

// MARK: - URLs (replace with your actual links)

private enum AppURL {
    static let privacyPolicy = "https://www.termsfeed.com/live/435d9f2d-31b2-4765-8820-04140acf97be"
    static let termsOfUse = "https://www.termsfeed.com/live/d0485f9e-a9f0-4f7f-8ab7-d728ce8bc065"
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground
                    .ignoresSafeArea()

                List {
                    Section {
                        SettingsRow(
                            icon: "star.fill",
                            title: "Rate us",
                            subtitle: "Help us with your feedback"
                        ) {
                            rateApp()
                        }

                        SettingsRow(
                            icon: "hand.raised.fill",
                            title: "Privacy Policy",
                            subtitle: "How we handle your data"
                        ) {
                            openURL(AppURL.privacyPolicy)
                        }

                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Use",
                            subtitle: "Terms and conditions"
                        ) {
                            openURL(AppURL.termsOfUse)
                        }
                    } header: {
                        Text("Legal & Support")
                            .foregroundColor(.strikeGold)
                    }
                    .listRowBackground(LinearGradient.cardSurface)
                    .listRowSeparatorTint(Color.strikeGray.opacity(0.3))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.strikeGold.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(LinearGradient.goldAccent)
                        .font(.body)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.headline)
                    Text(subtitle)
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
