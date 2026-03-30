import Foundation
import Combine

final class StrikeZoneViewModel: ObservableObject {
    // MARK: - Published properties

    @Published var players: [Player] = []
    @Published var currentPlayerId: UUID?
    @Published var selectedGameId: UUID?

    var currentPlayer: Player? {
        guard let id = currentPlayerId else { return players.first }
        return players.first { $0.id == id } ?? players.first
    }

    // MARK: - Game scoring

    func calculateScore(for game: Game) -> Int {
        var totalScore = 0

        for index in 0..<game.frames.count {
            let frame = game.frames[index]

            if frame.isStrike {
                // Strike: 10 + next two rolls
                totalScore += 10

                if index < 9 {
                    let nextFrame = game.frames[index + 1]
                    totalScore += nextFrame.firstShot

                    if nextFrame.isStrike {
                        if index + 2 < game.frames.count {
                            totalScore += game.frames[index + 2].firstShot
                        }
                    } else {
                        totalScore += nextFrame.secondShot ?? 0
                    }
                } else {
                    // 10th frame
                    totalScore += frame.secondShot ?? 0
                    totalScore += frame.thirdShot ?? 0
                }
            } else if frame.isSpare {
                // Spare: 10 + next roll
                totalScore += 10

                if index < 9 {
                    totalScore += game.frames[index + 1].firstShot
                } else {
                    totalScore += frame.thirdShot ?? 0
                }
            } else {
                // Open frame
                totalScore += frame.pinsInFrame
            }
        }

        return totalScore
    }

    func calculateGameStats(_ game: Game) -> (strikes: Int, spares: Int, opens: Int, splits: Int, gutters: Int) {
        var strikes = 0
        var spares = 0
        var opens = 0
        var splits = 0
        var gutters = 0

        for frame in game.frames {
            if frame.isStrike {
                strikes += 1
            } else if frame.isSpare {
                spares += 1
            } else {
                opens += 1
            }

            if frame.firstShot == 0 {
                gutters += 1
            }

            // Split detection can be added later if needed
            if frame.shotType == .split {
                splits += 1
            }
        }

        return (strikes, spares, opens, splits, gutters)
    }

    // MARK: - CRUD operations

    func addPlayer(name: String) {
        let newPlayer = Player(id: UUID(), name: name, games: [])
        players.append(newPlayer)

        if currentPlayerId == nil {
            currentPlayerId = newPlayer.id
        }

        saveToUserDefaults()
    }

    func addGame(for playerId: UUID, frames: [Frame], location: String?, notes: String?) {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }) else { return }

        var game = Game(
            id: UUID(),
            date: Date(),
            frames: frames,
            totalScore: 0,
            strikesCount: 0,
            sparesCount: 0,
            opensCount: 0,
            splitsCount: 0,
            guttersCount: 0,
            notes: notes,
            location: location
        )

        game.totalScore = calculateScore(for: game)
        let stats = calculateGameStats(game)
        game.strikesCount = stats.strikes
        game.sparesCount = stats.spares
        game.opensCount = stats.opens
        game.splitsCount = stats.splits
        game.guttersCount = stats.gutters

        players[playerIndex].games.append(game)
        selectedGameId = game.id
        saveToUserDefaults()
    }

    func updateGame(for playerId: UUID, updatedGame: Game) {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }) else { return }
        guard let gameIndex = players[playerIndex].games.firstIndex(where: { $0.id == updatedGame.id }) else { return }

        var game = updatedGame
        game.totalScore = calculateScore(for: game)
        let stats = calculateGameStats(game)
        game.strikesCount = stats.strikes
        game.sparesCount = stats.spares
        game.opensCount = stats.opens
        game.splitsCount = stats.splits
        game.guttersCount = stats.gutters

        players[playerIndex].games[gameIndex] = game
        selectedGameId = game.id
        saveToUserDefaults()
    }

    func deleteGame(_ game: Game, from playerId: UUID) {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }) else { return }
        players[playerIndex].games.removeAll { $0.id == game.id }
        saveToUserDefaults()
    }

    // MARK: - Statistics

    var allTimeStats: (totalGames: Int, totalStrikes: Int, totalSpares: Int, averageScore: Double) {
        guard !players.isEmpty else { return (0, 0, 0, 0) }

        let totalGames = players.reduce(0) { $0 + $1.games.count }
        let totalStrikes = players.reduce(0) { $0 + $1.totalStrikes }
        let totalSpares = players.reduce(0) { $0 + $1.totalSpares }
        let averageScore = players.reduce(0.0) { $0 + $1.averageScore } / Double(players.count)

        return (totalGames, totalStrikes, totalSpares, averageScore)
    }

    /// Trend: (recentAverage, previousAverage) — nil if not enough games
    func trend(for player: Player) -> (recent: Double, previous: Double)? {
        let sorted = player.games.sorted { $0.date > $1.date }
        guard sorted.count >= 6 else { return nil }
        let recent = Array(sorted.prefix(5))
        let previous = Array(sorted.dropFirst(5).prefix(5))
        let recentAvg = Double(recent.reduce(0) { $0 + $1.totalScore }) / Double(recent.count)
        let previousAvg = Double(previous.reduce(0) { $0 + $1.totalScore }) / Double(previous.count)
        return (recentAvg, previousAvg)
    }

    /// Average pins per frame number (1–10) across all games
    func frameAverages(for player: Player) -> [Int: Double] {
        var sums: [Int: Int] = (1...10).reduce(into: [:]) { $0[$1] = 0 }
        var counts: [Int: Int] = (1...10).reduce(into: [:]) { $0[$1] = 0 }
        for game in player.games {
            for (idx, frame) in game.frames.enumerated() where idx < 10 {
                let fn = idx + 1
                let contrib = frame.isStrike ? 10 : (frame.pinsInFrame)
                sums[fn, default: 0] += contrib
                counts[fn, default: 0] += 1
            }
        }
        return (1...10).reduce(into: [:]) { result, fn in
            let c = counts[fn] ?? 0
            result[fn] = c > 0 ? Double(sums[fn] ?? 0) / Double(c) : 0
        }
    }

    /// Max consecutive strikes in one game
    func maxStrikeStreak(in game: Game) -> Int {
        var maxStreak = 0
        var current = 0
        for frame in game.frames {
            if frame.isStrike {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    /// Number of "turkey" (3 strikes in a row) in a game
    func turkeyCount(in game: Game) -> Int {
        var count = 0
        var streak = 0
        for frame in game.frames {
            if frame.isStrike {
                streak += 1
                if streak >= 3 { count += 1 }
            } else {
                streak = 0
            }
        }
        return count
    }

    /// Number of "four-bagger" (4 strikes in a row) in a game
    func fourBaggerCount(in game: Game) -> Int {
        var count = 0
        var streak = 0
        for frame in game.frames {
            if frame.isStrike {
                streak += 1
                if streak >= 4 { count += 1 }
            } else {
                streak = 0
            }
        }
        return count
    }

    func totalTurkeys(for player: Player) -> Int {
        player.games.reduce(0) { $0 + turkeyCount(in: $1) }
    }

    func totalFourBaggers(for player: Player) -> Int {
        player.games.reduce(0) { $0 + fourBaggerCount(in: $1) }
    }

    /// Spare conversion: frames where first shot < 10 and first+second = 10 → spare. Percentage of such frames that were spares.
    func spareConversionRate(for player: Player) -> Double {
        var convertible = 0
        var converted = 0
        for game in player.games {
            for frame in game.frames {
                if frame.firstShot < 10 {
                    convertible += 1
                    if frame.isSpare { converted += 1 }
                }
            }
        }
        guard convertible > 0 else { return 0 }
        return Double(converted) / Double(convertible) * 100
    }

    /// Strike rate on first ball (percentage of frames that were strikes)
    func strikeRateFirstBall(for player: Player) -> Double {
        var totalFrames = 0
        var strikes = 0
        for game in player.games {
            for frame in game.frames {
                totalFrames += 1
                if frame.isStrike { strikes += 1 }
            }
        }
        guard totalFrames > 0 else { return 0 }
        return Double(strikes) / Double(totalFrames) * 100
    }

    /// How much this game is above/below player average (e.g. +12 or -5)
    func gameVsAverage(_ game: Game, player: Player) -> Int? {
        guard !player.games.isEmpty else { return nil }
        return game.totalScore - Int(player.averageScore)
    }

    /// Group games by (calendar day, location) for "series" display
    func seriesGroupedGames(for player: Player) -> [(title: String, games: [Game])] {
        let calendar = Calendar.current
        let sorted = player.games.sorted { $0.date > $1.date }
        var dict: [String: [Game]] = [:]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        for game in sorted {
            let day = calendar.startOfDay(for: game.date)
            let loc = (game.location?.isEmpty == false) ? (game.location ?? "—") : "—"
            let key = "\(formatter.string(from: day)) — \(loc)"
            dict[key, default: []].append(game)
        }
        return dict.map { (title: $0.key, games: $0.value.sorted { $0.date > $1.date }) }
            .sorted { ($0.games.first?.date ?? .distantPast) > ($1.games.first?.date ?? .distantPast) }
    }

    /// Duplicate last game frames for current player (for "Duplicate last game")
    func duplicateLastGameFrames(for playerId: UUID) -> [Frame]? {
        guard let player = players.first(where: { $0.id == playerId }),
              let last = player.games.sorted(by: { $0.date > $1.date }).first else { return nil }
        return last.frames.map { Frame(id: UUID(), frameNumber: $0.frameNumber, firstShot: $0.firstShot, secondShot: $0.secondShot, thirdShot: $0.thirdShot, shotType: $0.shotType) }
    }

    // MARK: - Locations

    @Published var locations: [Location] = []

    private let locationsKey = "strikezone_locations"

    func addLocation(name: String, address: String?) {
        let loc = Location(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), address: address?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : address?.trimmingCharacters(in: .whitespacesAndNewlines))
        locations.append(loc)
        saveLocations()
    }

    func updateLocation(_ location: Location) {
        guard let idx = locations.firstIndex(where: { $0.id == location.id }) else { return }
        locations[idx] = location
        saveLocations()
    }

    func deleteLocation(_ location: Location) {
        locations.removeAll { $0.id == location.id }
        saveLocations()
    }

    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }
    }

    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([Location].self, from: data) {
            locations = decoded
        }
    }

    // MARK: - Goals

    @Published var goals: [Goal] = []

    private let goalsKey = "strikezone_goals"

    func goals(for playerId: UUID) -> [Goal] {
        goals.filter { $0.playerId == playerId }
    }

    func addGoal(playerId: UUID, type: GoalType, targetValue: Int) {
        let goal = Goal(id: UUID(), playerId: playerId, goalType: type, targetValue: targetValue, createdAt: Date())
        goals.append(goal)
        saveGoals()
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }

    func deleteGoalsForPlayer(_ playerId: UUID) {
        goals.removeAll { $0.playerId == playerId }
        saveGoals()
    }

    func currentValue(for goal: Goal, player: Player) -> Int {
        switch goal.goalType {
        case .averageScore: return Int(player.averageScore)
        case .bestGame: return player.bestGame
        case .totalGames: return player.games.count
        case .totalStrikes: return player.totalStrikes
        case .totalSpares: return player.totalSpares
        case .gamesOver200: return player.games.filter { $0.totalScore >= 200 }.count
        }
    }

    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
    }

    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
        }
    }

    // MARK: - Persistence

    private let playersKey = "strikezone_players"

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(encoded, forKey: playersKey)
        }
    }

    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: playersKey),
           let decoded = try? JSONDecoder().decode([Player].self, from: data) {
            players = decoded
        }

        if players.isEmpty {
            loadDemoData()
        }

        if currentPlayerId == nil, let first = players.first {
            currentPlayerId = first.id
        }

        loadLocations()
        loadGoals()
    }

    private func loadDemoData() {
        let player = Player(id: UUID(), name: "Alex", games: [])
        players = [player]
        currentPlayerId = player.id

        var frames: [Frame] = []
        for i in 1...10 {
            let frame: Frame
            if i == 1 {
                frame = Frame(id: UUID(), frameNumber: i, firstShot: 10, secondShot: nil, thirdShot: nil, shotType: .strike)
            } else if i == 2 {
                frame = Frame(id: UUID(), frameNumber: i, firstShot: 7, secondShot: 2, thirdShot: nil, shotType: .open)
            } else if i == 3 {
                frame = Frame(id: UUID(), frameNumber: i, firstShot: 9, secondShot: 1, thirdShot: nil, shotType: .spare)
            } else {
                frame = Frame(id: UUID(), frameNumber: i, firstShot: 8, secondShot: 1, thirdShot: nil, shotType: .open)
            }
            frames.append(frame)
        }

        addGame(for: player.id, frames: frames, location: "Bowling Center", notes: "First game of the season")
    }
}

