import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var viewModel: StrikeZoneViewModel
    @State private var showingAddGoal = false

    private var selectedPlayerBinding: Binding<UUID> {
        Binding(
            get: {
                viewModel.currentPlayer?.id ?? viewModel.players.first?.id ?? UUID()
            },
            set: { newValue in
                viewModel.currentPlayerId = newValue
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    LinearGradient.screenBackground
                        .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        if let player = viewModel.currentPlayer {
                            if !player.games.isEmpty {
                                trendSection(player)
                                chartSection(for: player)
                                frameAveragesSection(player)
                                streaksSection(player)
                                conversionSection(player)
                                goalsSection(player)
                                achievementsSection(for: player)
                                frameDistributionSection(for: player)
                            } else {
                                noGamesSection
                            }
                        } else {
                            emptyStateSection
                        }
                    }
                    .padding()
                }
            }
//            .navigationTitle("Stats")
//            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddGoal) {
                if let player = viewModel.currentPlayer {
                    AddGoalView(viewModel: viewModel, player: player)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.title2)
                .bold()
                .shadow(color: Color.strikeGold.opacity(0.3), radius: 4, x: 0, y: 1)

            if !viewModel.players.isEmpty {
                Picker("Player", selection: selectedPlayerBinding) {
                    ForEach(viewModel.players) { player in
                        Text(player.name).tag(player.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(.strikeGold)
            }

            if let player = viewModel.currentPlayer {
                Text("Games: \(player.games.count) • Average: \(Int(player.averageScore)) • Best: \(player.bestGame)")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            }
        }
    }

    private func trendSection(_ player: Player) -> some View {
        Group {
            if let trend = viewModel.trend(for: player) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trend")
                        .foregroundColor(.strikeGold)
                        .font(.headline)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last 5 games")
                                .foregroundColor(.strikeGray)
                                .font(.caption)
                            Text(String(format: "%.0f", trend.recent))
                                .foregroundColor(.white)
                                .font(.title2)
                                .bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Previous 5")
                                .foregroundColor(.strikeGray)
                                .font(.caption)
                            Text(String(format: "%.0f", trend.previous))
                                .foregroundColor(.white)
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                        let improving = trend.recent > trend.previous
                        let stable = abs(trend.recent - trend.previous) < 2
                        Text(stable ? "Stable" : (improving ? "Improving" : "Declining"))
                            .foregroundColor(stable ? .strikeGray : (improving ? .strikeGold : .strikeGray))
                            .font(.subheadline)
                            .bold()
                    }
                    .padding()
                    .background(LinearGradient.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient.goldStroke, lineWidth: 0.8)
                    )
                    .cornerRadius(12)
                    .cardShadow()
                }
            }
        }
    }

    private func chartSection(for player: Player) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Games history")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            Chart {
                ForEach(Array(player.games.sorted(by: { $0.date < $1.date }).enumerated()), id: \.offset) { index, game in
                    LineMark(
                        x: .value("Game", index + 1),
                        y: .value("Score", game.totalScore)
                    )
                    .foregroundStyle(Color.strikeGold)

                    PointMark(
                        x: .value("Game", index + 1),
                        y: .value("Score", game.totalScore)
                    )
                    .foregroundStyle(Color.strikeGold)
                }
            }
            .frame(height: 200)
            .background(LinearGradient.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.strikeGray.opacity(0.2), lineWidth: 0.8)
            )
            .cornerRadius(14)
            .cardShadow()
        }
    }

    private func frameAveragesSection(_ player: Player) -> some View {
        let averages = viewModel.frameAverages(for: player)
        let best = averages.max(by: { $0.value < $1.value })
        let worst = averages.min(by: { $0.value < $1.value })

        return VStack(alignment: .leading, spacing: 8) {
            Text("Frame averages")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                if let b = best {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best frame")
                            .foregroundColor(.strikeGray)
                            .font(.caption)
                        Text("Frame \(b.key): \(String(format: "%.1f", b.value))")
                            .foregroundColor(.strikeGold)
                            .font(.subheadline)
                            .bold()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.strikeGold.opacity(0.3), lineWidth: 0.8)
                    )
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                }
                if let w = worst, w.value < (best?.value ?? 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weakest frame")
                            .foregroundColor(.strikeGray)
                            .font(.caption)
                        Text("Frame \(w.key): \(String(format: "%.1f", w.value))")
                            .foregroundColor(.strikeGray)
                            .font(.subheadline)
                            .bold()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.strikeGray.opacity(0.3), lineWidth: 0.8)
                    )
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(1...10, id: \.self) { fn in
                        let avg = averages[fn] ?? 0
                        VStack(spacing: 2) {
                            Text("\(fn)")
                                .foregroundColor(.strikeGray)
                                .font(.caption2)
                            Text(String(format: "%.1f", avg))
                                .foregroundColor(.white)
                                .font(.caption)
                                .bold()
                        }
                        .frame(width: 36, height: 44)
                        .background(LinearGradient.cardSurfaceLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                }
            }
        }
    }

    private func streaksSection(_ player: Player) -> some View {
        let sortedGames = player.games.sorted { $0.date > $1.date }
        let maxStreak = sortedGames.map { viewModel.maxStrikeStreak(in: $0) }.max() ?? 0
        let turkeys = viewModel.totalTurkeys(for: player)
        let fourBaggers = viewModel.totalFourBaggers(for: player)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Streaks")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            HStack(spacing: 12) {
                StatBox(title: "Max strike streak", value: "\(maxStreak)", icon: "flame.fill", color: .strikeGold)
                StatBox(title: "Turkeys (3 in a row)", value: "\(turkeys)", icon: "star.fill", color: .strikeGold.opacity(0.8))
                StatBox(title: "Four-baggers", value: "\(fourBaggers)", icon: "bolt.fill", color: .strikeGold.opacity(0.7))
            }
        }
    }

    private func conversionSection(_ player: Player) -> some View {
        let spareRate = viewModel.spareConversionRate(for: player)
        let strikeRate = viewModel.strikeRateFirstBall(for: player)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Conversion")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strike rate (1st ball)")
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                    Text(String(format: "%.0f%%", strikeRate))
                        .foregroundColor(.strikeGold)
                        .font(.title3)
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.strikeGold.opacity(0.25), lineWidth: 0.8)
                )
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Spare conversion")
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                    Text(String(format: "%.0f%%", spareRate))
                        .foregroundColor(.strikeGold.opacity(0.9))
                        .font(.title3)
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.strikeGold.opacity(0.2), lineWidth: 0.8)
                )
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
            }
        }
    }

    private func goalsSection(_ player: Player) -> some View {
        let playerGoals = viewModel.goals(for: player.id)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Goals")
                    .foregroundStyle(LinearGradient.goldAccent)
                    .font(.headline)
                Spacer()
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LinearGradient.goldAccent)
                        .shadow(color: Color.strikeGold.opacity(0.4), radius: 3, x: 0, y: 1)
                }
            }

            if playerGoals.isEmpty {
                Text("Add a goal to track your progress.")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
                    .padding(.vertical, 4)
            } else {
                ForEach(playerGoals) { goal in
                    let current = viewModel.currentValue(for: goal, player: player)
                    let target = goal.targetValue
                    let progress = target > 0 ? min(Double(current) / Double(target), 1.0) : 0
                    let done = current >= target

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: goal.goalType.icon)
                                .foregroundColor(.strikeGold)
                            Text(goal.goalType.displayName)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(current)/\(target)")
                                .foregroundColor(done ? .strikeGold : .strikeGray)
                                .bold()
                            if done {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.strikeGold)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.strikeGray.opacity(0.25))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.strikeGold, Color.strikeGold.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(10)
                    .background(LinearGradient.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(done ? Color.strikeGold.opacity(0.4) : Color.strikeGray.opacity(0.2), lineWidth: 0.8)
                    )
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)

                    Button(role: .destructive) {
                        viewModel.deleteGoal(goal)
                    } label: {
                        Text("Remove goal")
                            .font(.caption)
                    }
                    .opacity(0.9)
                }
            }
        }
    }

    private func achievementsSection(for player: Player) -> some View {
        let games = player.games
        let totalStrikes = player.totalStrikes
        let games200 = games.filter { $0.totalScore >= 200 }.count
        let perfectCount = games.filter { $0.totalScore == 300 }.count
        let turkeys = viewModel.totalTurkeys(for: player)
        let fourBaggers = viewModel.totalFourBaggers(for: player)
        let hasStrike = totalStrikes >= 1
        let hasSpare = player.totalSpares >= 1
        let has100 = games.contains { $0.totalScore >= 100 }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            AchievementRow(title: "100 strikes", current: totalStrikes, target: 100, color: .strikeGold)
            AchievementRow(title: "Games 200+", current: games200, target: 10, color: .strikeGold)
            AchievementRow(title: "Perfect game (300)", current: perfectCount, target: 1, color: .strikeGold)
            AchievementRow(title: "Turkeys (3 strikes)", current: turkeys, target: 10, color: .strikeGold.opacity(0.9))
            AchievementRow(title: "Four-bagger", current: fourBaggers, target: 1, color: .strikeGold.opacity(0.8))

            Text("Firsts")
                .foregroundColor(.strikeGray)
                .font(.caption)
            HStack(spacing: 12) {
                achievementBadge(icon: "star.fill", title: "First strike", done: hasStrike)
                achievementBadge(icon: "bolt.fill", title: "First spare", done: hasSpare)
                achievementBadge(icon: "target", title: "Game 100+", done: has100)
            }
        }
    }

    private func achievementBadge(icon: String, title: String, done: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(done ? .strikeGold : .strikeGray.opacity(0.6))
            Text(title)
                .foregroundColor(done ? .white : .strikeGray)
                .font(.caption2)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            done
                ? LinearGradient(
                    colors: [Color.strikeGold.opacity(0.28), Color.strikeGold.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient.cardSurface
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(done ? Color.strikeGold.opacity(0.4) : Color.strikeGray.opacity(0.2), lineWidth: 0.6)
        )
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }

    private func frameDistributionSection(for player: Player) -> some View {
        let totals = player.games.reduce((strikes: 0, spares: 0, opens: 0)) { partial, game in
            var next = partial
            next.strikes += game.strikesCount
            next.spares += game.sparesCount
            next.opens += game.opensCount
            return next
        }
        let totalFrames = totals.strikes + totals.spares + totals.opens
        let hasData = totalFrames > 0

        return VStack(alignment: .leading, spacing: 8) {
            Text("Frame distribution")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            if hasData {
                Chart {
                    if totals.strikes > 0 {
                        SectorMark(angle: .value("Count", totals.strikes))
                            .foregroundStyle(Color.strikeGold)
                    }
                    if totals.spares > 0 {
                        SectorMark(angle: .value("Count", totals.spares))
                            .foregroundStyle(Color.strikeGold.opacity(0.7))
                    }
                    if totals.opens > 0 {
                        SectorMark(angle: .value("Count", totals.opens))
                            .foregroundStyle(Color.strikeGray)
                    }
                }
                .frame(height: 180)
                .background(LinearGradient.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.strikeGray.opacity(0.2), lineWidth: 0.8)
                )
                .cornerRadius(14)
                .cardShadow()
            } else {
                Text("No frame data yet.")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            }
        }
    }

    private var noGamesSection: some View {
        VStack(spacing: 12) {
            Text("No games yet")
                .foregroundColor(.white)
                .font(.headline)
            Text("Play some games to see statistics here.")
                .foregroundColor(.strikeGray)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No players yet")
                .foregroundColor(.white)
                .font(.headline)
            Text("Go to the Players tab to add your first player.")
                .foregroundColor(.strikeGray)
                .font(.caption)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Add Goal Sheet

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StrikeZoneViewModel
    let player: Player

    @State private var selectedType: GoalType = .averageScore
    @State private var targetValue: String = "150"

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal type")
                            .foregroundColor(.strikeGold)
                            .font(.caption)
                        Picker("Type", selection: $selectedType) {
                            ForEach(GoalType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.strikeGold)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target")
                            .foregroundColor(.strikeGold)
                            .font(.caption)
                        TextField("Target value", text: $targetValue)
                            .keyboardType(.numberPad)
                            .padding(10)
                            .background(LinearGradient.cardSurfaceLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.strikeGray.opacity(0.25), lineWidth: 0.8)
                            )
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.strikeGray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addGoal() }
                        .foregroundColor(.strikeGold)
                        .disabled(Int(targetValue) == nil || (Int(targetValue) ?? 0) <= 0)
                }
            }
        }
    }

    private func addGoal() {
        guard let value = Int(targetValue), value > 0 else { return }
        viewModel.addGoal(playerId: player.id, type: selectedType, targetValue: value)
        dismiss()
    }
}
