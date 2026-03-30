import Foundation
import SwiftUI

// MARK: - Color palette & design tokens

extension Color {
    static let strikeBackground = Color(red: 0.0, green: 0.137, blue: 0.373) // #00235F
    static let strikeGold = Color(red: 1.0, green: 0.757, blue: 0.196) // #FFC132
    static let strikeGray = Color(red: 0.396, green: 0.396, blue: 0.396) // #656565

    /// Darker blue for gradient depth
    static let strikeBackgroundDark = Color(red: 0.0, green: 0.08, blue: 0.25)
}

// MARK: - Gradients

extension LinearGradient {
    static let screenBackground = LinearGradient(
        colors: [Color.strikeBackgroundDark, Color.strikeBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardSurface = LinearGradient(
        colors: [
            Color.strikeGray.opacity(0.22),
            Color.strikeGray.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardSurfaceLight = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.strikeGray.opacity(0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldButton = LinearGradient(
        colors: [
            Color.strikeGold,
            Color.strikeGold.opacity(0.82),
            Color(red: 0.9, green: 0.65, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldAccent = LinearGradient(
        colors: [
            Color.strikeGold.opacity(0.9),
            Color.strikeGold.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldStroke = LinearGradient(
        colors: [
            Color.strikeGold.opacity(0.6),
            Color.strikeGold.opacity(0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View modifiers for shadows & depth

struct CardShadowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct GoldGlowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.strikeGold.opacity(0.35), radius: 8, x: 0, y: 2)
            .shadow(color: Color.strikeGold.opacity(0.15), radius: 2, x: 0, y: 0)
    }
}

extension View {
    func cardShadow() -> some View { modifier(CardShadowStyle()) }
    func goldGlow() -> some View { modifier(GoldGlowStyle()) }
}

// MARK: - Models

enum ShotType: String, CaseIterable, Codable {
    case strike
    case spare
    case open
    case split
    case gutter

    var displayName: String {
        switch self {
        case .strike: return "Strike"
        case .spare: return "Spare"
        case .open: return "Open"
        case .split: return "Split"
        case .gutter: return "Gutter"
        }
    }

    var color: Color {
        switch self {
        case .strike: return .strikeGold
        case .spare: return .strikeGold.opacity(0.8)
        case .open: return .strikeGray
        case .split: return .strikeGray.opacity(0.8)
        case .gutter: return .strikeGray.opacity(0.5)
        }
    }

    var pins: Int {
        switch self {
        case .strike: return 10
        case .spare: return 10
        case .open: return 0
        case .split: return 0
        case .gutter: return 0
        }
    }
}

struct Frame: Identifiable, Codable {
    let id: UUID
    let frameNumber: Int // 1-10
    var firstShot: Int
    var secondShot: Int?
    var thirdShot: Int?
    var shotType: ShotType?

    var isStrike: Bool {
        firstShot == 10
    }

    var isSpare: Bool {
        guard !isStrike, let second = secondShot else { return false }
        return firstShot + second == 10
    }

    var pinsInFrame: Int {
        if isStrike {
            return 10
        } else if let second = secondShot {
            return firstShot + second
        } else {
            return firstShot
        }
    }

    var displayValue: String {
        if isStrike {
            return "X"
        } else if isSpare {
            return "\(firstShot) /"
        } else if let second = secondShot {
            return "\(firstShot) \(second)"
        } else {
            return "\(firstShot)"
        }
    }
}

struct Game: Identifiable, Codable {
    let id: UUID
    let date: Date
    var frames: [Frame]
    var totalScore: Int
    var strikesCount: Int
    var sparesCount: Int
    var opensCount: Int
    var splitsCount: Int
    var guttersCount: Int
    var notes: String?
    var location: String?

    var averageScore: Int {
        totalScore
    }

    var strikePercentage: Double {
        guard !frames.isEmpty else { return 0 }
        return Double(strikesCount) / Double(frames.count) * 100
    }

    var sparePercentage: Double {
        guard !frames.isEmpty else { return 0 }
        return Double(sparesCount) / Double(frames.count) * 100
    }
}

struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var games: [Game]

    var averageScore: Double {
        guard !games.isEmpty else { return 0 }
        let sum = games.reduce(0) { $0 + $1.totalScore }
        return Double(sum) / Double(games.count)
    }

    var bestGame: Int {
        games.max(by: { $0.totalScore < $1.totalScore })?.totalScore ?? 0
    }

    var totalStrikes: Int {
        games.reduce(0) { $0 + $1.strikesCount }
    }

    var totalSpares: Int {
        games.reduce(0) { $0 + $1.sparesCount }
    }

    var avatarLetter: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .first?
            .prefix(1)
            .uppercased() ?? "P"
    }
}

// MARK: - Location (bowling center)

struct Location: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var address: String?

    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Goal

enum GoalType: String, CaseIterable, Codable {
    case averageScore
    case bestGame
    case totalGames
    case totalStrikes
    case totalSpares
    case gamesOver200

    var displayName: String {
        switch self {
        case .averageScore: return "Average score"
        case .bestGame: return "Best game"
        case .totalGames: return "Total games"
        case .totalStrikes: return "Total strikes"
        case .totalSpares: return "Total spares"
        case .gamesOver200: return "Games 200+"
        }
    }

    var icon: String {
        switch self {
        case .averageScore: return "target"
        case .bestGame: return "trophy.fill"
        case .totalGames: return "number"
        case .totalStrikes: return "star.fill"
        case .totalSpares: return "bolt.fill"
        case .gamesOver200: return "flame.fill"
        }
    }
}

struct Goal: Identifiable, Codable {
    let id: UUID
    let playerId: UUID
    var goalType: GoalType
    var targetValue: Int
    let createdAt: Date
}

