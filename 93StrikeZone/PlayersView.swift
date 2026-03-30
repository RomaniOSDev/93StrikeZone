import SwiftUI

struct PlayersView: View {
    @ObservedObject var viewModel: StrikeZoneViewModel

    @State private var newPlayerName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    playersList
                    addPlayerSection
                }
                .padding()
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Text("Players")
            .foregroundStyle(LinearGradient.goldAccent)
            .font(.title2)
            .bold()
            .shadow(color: Color.strikeGold.opacity(0.3), radius: 4, x: 0, y: 1)
    }

    private var playersList: some View {
        Group {
            if viewModel.players.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text("No players yet")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Create a player to start tracking games.")
                        .foregroundColor(.strikeGray)
                        .font(.caption)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.players) { player in
                        Button {
                            viewModel.currentPlayerId = player.id
                        } label: {
                            playerRow(for: player)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        deletePlayers(at: indexSet)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func playerRow(for player: Player) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.strikeGray.opacity(0.4), Color.strikeGray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient.goldStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                Text(player.avatarLetter)
                    .foregroundColor(.strikeGold)
                    .font(.title2)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .foregroundColor(.white)
                    .font(.headline)

                Text("Average: \(Int(player.averageScore)) • Best: \(player.bestGame)")
                    .foregroundColor(.strikeGray)
                    .font(.caption)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(player.games.count) games")
                    .foregroundColor(.strikeGold)
                    .font(.caption)

                if viewModel.currentPlayerId == player.id {
                    Text("Current")
                        .foregroundColor(.strikeGold)
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(viewModel.currentPlayerId == player.id ? Color.strikeGold.opacity(0.4) : Color.strikeGray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(14)
        .cardShadow()
    }

    private var addPlayerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add player")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Player name", text: $newPlayerName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(10)
                    .background(LinearGradient.cardSurfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.strikeGray.opacity(0.25), lineWidth: 0.8)
                    )
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                Button {
                    addPlayer()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LinearGradient.goldAccent)
                        .font(.title2)
                        .shadow(color: Color.strikeGold.opacity(0.4), radius: 3, x: 0, y: 1)
                }
                .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func addPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.addPlayer(name: trimmed)
        newPlayerName = ""
    }

    private func deletePlayers(at offsets: IndexSet) {
        let toDelete = offsets.map { viewModel.players[$0].id }
        for playerId in toDelete {
            viewModel.deleteGoalsForPlayer(playerId)
        }
        viewModel.players.remove(atOffsets: offsets)

        if let currentId = viewModel.currentPlayerId,
           !viewModel.players.contains(where: { $0.id == currentId }) {
            viewModel.currentPlayerId = viewModel.players.first?.id
        }

        viewModel.saveToUserDefaults()
    }
}

