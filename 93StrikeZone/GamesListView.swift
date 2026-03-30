import SwiftUI

struct GamesListView: View {
    @ObservedObject var viewModel: StrikeZoneViewModel
    @State private var showingNewGame = false
    @State private var duplicateFrames: [Frame]?

    private var selectedPlayerIdBinding: Binding<UUID> {
        Binding(
            get: {
                viewModel.currentPlayer?.id ?? viewModel.players.first?.id ?? UUID()
            },
            set: { newValue in
                viewModel.currentPlayerId = newValue
            }
        )
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    headerSection

                    if let player = viewModel.currentPlayer {
                        statsSection(for: player)
                        gamesSection(for: player)
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let player = viewModel.currentPlayer {
                        HStack(spacing: 12) {
                            if viewModel.duplicateLastGameFrames(for: player.id) != nil {
                                Button {
                                    duplicateFrames = viewModel.duplicateLastGameFrames(for: player.id)
                                    showingNewGame = true
                                } label: {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.strikeGold)
                                        .font(.title3)
                                }
                                .accessibilityLabel("Duplicate last game")
                            }
                            Button {
                                duplicateFrames = nil
                                showingNewGame = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.strikeGold)
                                    .font(.title2)
                            }
                            .accessibilityLabel("Add game")
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

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("StrikeZone")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.largeTitle)
                .bold()
                .shadow(color: Color.strikeGold.opacity(0.4), radius: 6, x: 0, y: 2)

            HStack {
                if !viewModel.players.isEmpty {
                    Picker("Player", selection: selectedPlayerIdBinding) {
                        ForEach(viewModel.players) { player in
                            Text(player.name).tag(player.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.strikeGold)
                }

                Spacer()
            }

            if let player = viewModel.currentPlayer {
                Text("Games: \(player.games.count) • Average: \(Int(player.averageScore)) • Best: \(player.bestGame)")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            } else {
                Text("Add a player to start tracking games.")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            }
        }
    }

    private func statsSection(for player: Player) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(title: "Average score", value: "\(Int(player.averageScore))", icon: "target")
                StatCard(title: "Best game", value: "\(player.bestGame)", icon: "trophy.fill")
                StatCard(title: "Total strikes", value: "\(player.totalStrikes)", icon: "star.fill")
                StatCard(title: "Total spares", value: "\(player.totalSpares)", icon: "bolt.fill")
            }
        }
    }

    private func gamesSection(for player: Player) -> some View {
        Group {
            if player.games.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text("No games yet")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Tap the + button to add your first game.")
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.seriesGroupedGames(for: player), id: \.title) { series in
                        Section(header: Text(series.title)
                            .foregroundColor(.strikeGold)
                            .font(.subheadline)
                            .listRowBackground(Color.clear)) {
                            ForEach(series.games) { game in
                                NavigationLink {
                                    GameDetailView(viewModel: viewModel, player: player, game: game)
                                } label: {
                                    gameCard(for: game)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    viewModel.deleteGame(series.games[index], from: player.id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
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
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func gameCard(for game: Game) -> some View {
        let formattedDate = dateFormatter.string(from: game.date)
        let formattedTime = timeFormatter.string(from: game.date)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .foregroundColor(.white)
                        .font(.headline)
                    Text(formattedTime)
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                }

                Spacer()

                Text("\(game.totalScore)")
                    .foregroundStyle(LinearGradient.goldAccent)
                    .font(.largeTitle)
                    .bold()
                    .shadow(color: Color.strikeGold.opacity(0.35), radius: 4, x: 0, y: 1)
            }

            HStack(spacing: 4) {
                ForEach(game.frames.prefix(5)) { frame in
                    FramePreview(frame: frame)
                }

                if game.frames.count > 5 {
                    Text("...")
                        .foregroundColor(.strikeGray)
                }
            }

            HStack {
                Label("\(game.strikesCount)", systemImage: "star.fill")
                    .foregroundColor(.strikeGold)
                    .font(.caption)

                Label("\(game.sparesCount)", systemImage: "bolt.fill")
                    .foregroundColor(.strikeGold.opacity(0.8))
                    .font(.caption)

                Label("\(game.opensCount)", systemImage: "circle")
                    .foregroundColor(.strikeGray)
                    .font(.caption)

                if let location = game.location, !location.isEmpty {
                    Spacer()
                    Label(location, systemImage: "location.fill")
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(LinearGradient.goldStroke, lineWidth: 1)
        )
        .cornerRadius(14)
        .cardShadow()
    }

}

