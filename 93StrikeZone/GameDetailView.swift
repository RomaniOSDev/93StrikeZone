import SwiftUI

struct GameDetailView: View {
    @ObservedObject var viewModel: StrikeZoneViewModel
    let player: Player
    let game: Game

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                statsSection
                framesSection
                notesSection
                actionButtons
            }
            .padding()
        }
        .background(LinearGradient.screenBackground.ignoresSafeArea())
        .navigationTitle("Game details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            NewGameView(viewModel: viewModel, player: player, gameToEdit: game)
        }
        .alert("Delete game", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteGame(game, from: player.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this game?")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Total score")
                .foregroundColor(.strikeGray)
                .font(.headline)

            Text("\(game.totalScore)")
                .foregroundStyle(LinearGradient.goldButton)
                .font(.system(size: 72, weight: .bold))
                .goldGlow()

            Text(dateFormatter.string(from: game.date))
                .foregroundColor(.white)

            if let location = game.location, !location.isEmpty {
                Text(location)
                    .foregroundColor(.strikeGray)
            }

            if let diff = viewModel.gameVsAverage(game, player: player), diff != 0 {
                Text(diff > 0 ? "+\(diff) vs average" : "\(diff) vs average")
                    .foregroundColor(diff > 0 ? .strikeGold : .strikeGray)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient.goldStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .cardShadow()
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBox(title: "Strikes", value: "\(game.strikesCount)", icon: "star.fill", color: .strikeGold)
            StatBox(title: "Spares", value: "\(game.sparesCount)", icon: "bolt.fill", color: .strikeGold.opacity(0.8))
            StatBox(title: "Open", value: "\(game.opensCount)", icon: "circle", color: .strikeGray)
            StatBox(title: "Splits", value: "\(game.splitsCount)", icon: "square.split.2x2", color: .strikeGray)
            StatBox(title: "Gutters", value: "\(game.guttersCount)", icon: "g.circle", color: .strikeGray)
            StatBox(title: "Strike %", value: String(format: "%.0f%%", game.strikePercentage), icon: "percent", color: .strikeGold)
        }
        .padding()
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.strikeGray.opacity(0.2), lineWidth: 0.8)
        )
        .cornerRadius(14)
        .cardShadow()
    }

    private var framesSection: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(1...10, id: \.self) { index in
                    Text("\(index)")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.strikeGold)
                        .font(.caption)
                }
            }

            HStack(alignment: .top, spacing: 4) {
                ForEach(game.frames) { frame in
                    VStack(spacing: 2) {
                        Text(frame.firstShot == 10 ? "X" : "\(frame.firstShot)")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(frame.isStrike ? .strikeGold : .white)

                        if let second = frame.secondShot {
                            Text(frame.isSpare ? "/" : "\(second)")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(frame.isSpare ? .strikeGold : .white)
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity)
                        }

                        if let third = frame.thirdShot {
                            Text(third == 10 ? "X" : "\(third)")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.strikeGold)
                        }
                    }
                    .padding(6)
                    .background(
                        LinearGradient(
                            colors: [Color.strikeGray.opacity(0.3), Color.strikeGray.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
            }
        }
        .padding()
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.strikeGray.opacity(0.2), lineWidth: 0.8)
        )
        .cornerRadius(14)
        .cardShadow()
    }

    private var notesSection: some View {
        Group {
            if let notes = game.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .foregroundColor(.strikeGold)
                        .font(.headline)

                    Text(notes)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient.cardSurfaceLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.strikeGray.opacity(0.2), lineWidth: 0.6)
                        )
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingEditSheet = true
            } label: {
                Text("Edit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.goldButton)
                    .foregroundColor(.strikeBackground)
                    .cornerRadius(12)
                    .goldGlow()
            }
            .buttonStyle(.plain)

            Button {
                showingDeleteAlert = true
            } label: {
                Text("Delete")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient.goldStroke, lineWidth: 1.2)
                    )
                    .foregroundColor(.strikeGold)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

