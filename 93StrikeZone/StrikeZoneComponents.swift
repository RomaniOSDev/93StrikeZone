import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(LinearGradient.goldAccent)
                    .font(.subheadline)
                Text(title)
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            }

            Text(value)
                .foregroundColor(.white)
                .font(.title2)
                .bold()
        }
        .padding()
        .frame(width: 160, alignment: .leading)
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient.goldStroke, lineWidth: 0.8)
        )
        .cornerRadius(12)
        .cardShadow()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 1)

            Text(value)
                .foregroundColor(.white)
                .font(.title3)
                .bold()

            Text(title)
                .foregroundColor(.strikeGray)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.25), lineWidth: 0.6)
        )
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct FramePreview: View {
    let frame: Frame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.strikeGray.opacity(0.35),
                            Color.strikeGray.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(frame.isStrike || frame.isSpare ? Color.strikeGold.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

            Text(frame.displayValue)
                .foregroundColor(frame.isStrike || frame.isSpare ? .strikeGold : .white)
                .font(.caption)
                .bold()
        }
    }
}

struct AchievementRow: View {
    let title: String
    let current: Int
    let target: Int
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Text("\(current)/\(target)")
                    .foregroundColor(color)
                    .bold()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.strikeGray.opacity(0.25))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

