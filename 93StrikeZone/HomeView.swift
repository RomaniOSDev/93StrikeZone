import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: StrikeZoneViewModel
    @State private var showingNewGame = false
    @State private var duplicateFrames: [Frame]?

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }

    private var recentGames: [Game] {
        guard let player = viewModel.currentPlayer else { return [] }
        return Array(player.games.sorted { $0.date > $1.date }.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroSection
                        if let player = viewModel.currentPlayer {
                            playerCard(player)
                            statsGrid(player)
                            recentSection(player)
                            newGameButton
                        } else {
                            emptyPlayerSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentPlayer != nil {
                        HStack(spacing: 10) {
                            if viewModel.duplicateLastGameFrames(for: viewModel.currentPlayer!.id) != nil {
                                Button {
                                    duplicateFrames = viewModel.duplicateLastGameFrames(for: viewModel.currentPlayer!.id)
                                    showingNewGame = true
                                } label: {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.body)
                                        .foregroundStyle(LinearGradient.goldAccent)
                                }
                            }
                            Button {
                                duplicateFrames = nil
                                showingNewGame = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(LinearGradient.goldAccent)
                                    .shadow(color: Color.strikeGold.opacity(0.4), radius: 3, x: 0, y: 1)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewGame, onDismiss: { duplicateFrames = nil }) {
                if let player = viewModel.currentPlayer {
                    NewGameView(viewModel: viewModel, player: player, initialFrames: duplicateFrames)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
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
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(LinearGradient.goldStroke, lineWidth: 1.2)
                        )
                        .shadow(color: Color.strikeGold.opacity(0.3), radius: 8, x: 0, y: 3)
                    Image(systemName: "figure.bowling")
                        .font(.system(size: 28))
                        .foregroundStyle(LinearGradient.goldAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("StrikeZone")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.goldAccent)
                        .shadow(color: Color.strikeGold.opacity(0.5), radius: 6, x: 0, y: 2)
                    Text("Track your scores")
                        .font(.subheadline)
                        .foregroundColor(.strikeGray)
                }
                Spacer()
            }
            .padding(.vertical, 16)

            // Lane lines
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.strikeGold.opacity(0.15),
                                    Color.strikeGold.opacity(0.05),
                                    Color.strikeGold.opacity(0.02)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Player card

    private func playerCard(_ player: Player) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.strikeGray.opacity(0.45), Color.strikeGray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient.goldStroke, lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                Text(player.avatarLetter)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.strikeGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Current player")
                    .font(.caption)
                    .foregroundColor(.strikeGray)
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(player.games.count) games • Best: \(player.bestGame)")
                    .font(.caption)
                    .foregroundColor(.strikeGray)
            }
            Spacer()
        }
        .padding(16)
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient.goldStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .cardShadow()
    }

    // MARK: - Stats grid

    private func statsGrid(_ player: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your stats")
                .font(.headline)
                .foregroundStyle(LinearGradient.goldAccent)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Average", value: "\(Int(player.averageScore))", icon: "target")
                StatCard(title: "Best game", value: "\(player.bestGame)", icon: "trophy.fill")
                StatCard(title: "Total strikes", value: "\(player.totalStrikes)", icon: "star.fill")
                StatCard(title: "Total spares", value: "\(player.totalSpares)", icon: "bolt.fill")
            }
        }
    }

    // MARK: - Recent games

    private func recentSection(_ player: Player) -> some View {
        Group {
            if recentGames.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent games")
                        .font(.headline)
                        .foregroundStyle(LinearGradient.goldAccent)
                    Text("No games yet")
                        .font(.subheadline)
                        .foregroundColor(.strikeGray)
                    Text("Tap New game to log your first score.")
                        .font(.caption)
                        .foregroundColor(.strikeGray.opacity(0.9))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.strikeGold.opacity(0.35), lineWidth: 0.8)
                )
                .cornerRadius(16)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent games")
                            .font(.headline)
                            .foregroundStyle(LinearGradient.goldAccent)
                        Spacer()
                        NavigationLink {
                            GamesListView(viewModel: viewModel)
                        } label: {
                            Text("See all")
                                .font(.caption)
                                .foregroundColor(.strikeGold)
                        }
                    }

                    VStack(spacing: 10) {
                        ForEach(recentGames) { game in
                            NavigationLink {
                                GameDetailView(viewModel: viewModel, player: player, game: game)
                            } label: {
                                recentGameRow(game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func recentGameRow(_ game: Game) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: game.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(timeFormatter.string(from: game.date))
                    .font(.caption)
                    .foregroundColor(.strikeGray)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(game.frames.prefix(4)) { frame in
                    FramePreview(frame: frame)
                }
                if game.frames.count > 4 {
                    Text("…")
                        .font(.caption)
                        .foregroundColor(.strikeGray)
                }
            }
            Text("\(game.totalScore)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(LinearGradient.goldAccent)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(14)
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient.goldStroke, lineWidth: 0.8)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    // MARK: - New game CTA

    private var newGameButton: some View {
        Button {
            duplicateFrames = nil
            showingNewGame = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("New game")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.strikeBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.goldButton)
            .cornerRadius(14)
            .goldGlow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyPlayerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient.goldAccent)
                    .shadow(color: Color.strikeGold.opacity(0.3), radius: 6, x: 0, y: 2)
                Text("No player yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("Add a player in the Players tab to start tracking your games and stats.")
                    .font(.subheadline)
                    .foregroundColor(.strikeGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(LinearGradient.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient.goldStroke, lineWidth: 1)
            )
            .cornerRadius(20)
            .cardShadow()
        }
        .padding(.vertical, 8)
    }
}
