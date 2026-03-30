import SwiftUI

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: StrikeZoneViewModel
    let player: Player
    let gameToEdit: Game?
    /// When set, used as initial frames (e.g. "Duplicate last game")
    let initialFrames: [Frame]?

    @State private var frames: [Frame]
    @State private var location: String
    @State private var selectedLocationId: UUID?
    @State private var notes: String

    init(viewModel: StrikeZoneViewModel, player: Player, gameToEdit: Game? = nil, initialFrames: [Frame]? = nil) {
        self.viewModel = viewModel
        self.player = player
        self.gameToEdit = gameToEdit
        self.initialFrames = initialFrames

        if let gameToEdit = gameToEdit {
            _frames = State(initialValue: gameToEdit.frames)
            _location = State(initialValue: gameToEdit.location ?? "")
            _selectedLocationId = State(initialValue: nil)
            _notes = State(initialValue: gameToEdit.notes ?? "")
        } else if let initial = initialFrames, initial.count == 10 {
            _frames = State(initialValue: initial.map { Frame(id: UUID(), frameNumber: $0.frameNumber, firstShot: $0.firstShot, secondShot: $0.secondShot, thirdShot: $0.thirdShot, shotType: $0.shotType) })
            _location = State(initialValue: "")
            _selectedLocationId = State(initialValue: nil)
            _notes = State(initialValue: "")
        } else {
            let defaultFrames = (1...10).map {
                Frame(id: UUID(), frameNumber: $0, firstShot: 0, secondShot: nil, thirdShot: nil, shotType: nil)
            }
            _frames = State(initialValue: defaultFrames)
            _location = State(initialValue: "")
            _selectedLocationId = State(initialValue: nil)
            _notes = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            headerSection
                            framesSection
                            notesSection
                        }
                        .padding()
                    }

                    saveButton
                }
            }
            .navigationTitle(gameToEdit == nil ? "New Game" : "Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.strikeGray)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Player: \(player.name)")
                .foregroundStyle(LinearGradient.goldAccent)
                .font(.headline)

            if !viewModel.locations.isEmpty {
                Picker("Place", selection: $selectedLocationId) {
                    Text("Other (type below)").tag(nil as UUID?)
                    ForEach(viewModel.locations) { loc in
                        Text(loc.name).tag(Optional(loc.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.strikeGold)
                .onChange(of: selectedLocationId) { newValue in
                    if let id = newValue, let loc = viewModel.locations.first(where: { $0.id == id }) {
                        location = loc.name
                    }
                }
            }

            TextField("Bowling center (optional)", text: $location)
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
        }
    }

    private var framesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frames")
                .foregroundColor(.strikeGold)
                .font(.headline)

            ForEach(frames.indices, id: \.self) { index in
                FrameInputView(frameNumber: index + 1, frame: $frames[index])
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .foregroundColor(.strikeGold)
                .font(.headline)

            TextEditor(text: $notes)
                .frame(minHeight: 80, maxHeight: 140)
                .padding(8)
                .background(LinearGradient.cardSurfaceLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.strikeGray.opacity(0.25), lineWidth: 0.8)
                )
                .cornerRadius(10)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }

    private var saveButton: some View {
        Button {
            saveGame()
        } label: {
            Text(gameToEdit == nil ? "Save game" : "Save changes")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.goldButton)
                .foregroundColor(.strikeBackground)
                .cornerRadius(12)
                .goldGlow()
                .padding([.horizontal, .bottom])
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func saveGame() {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationValue = trimmedLocation.isEmpty ? nil : trimmedLocation
        let notesValue = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let gameToEdit = gameToEdit {
            var updatedGame = gameToEdit
            updatedGame.frames = frames
            updatedGame.location = locationValue
            updatedGame.notes = notesValue
            viewModel.updateGame(for: player.id, updatedGame: updatedGame)
        } else {
            viewModel.addGame(for: player.id, frames: frames, location: locationValue, notes: notesValue)
        }

        dismiss()
    }
}

struct FrameInputView: View {
    let frameNumber: Int
    @Binding var frame: Frame

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frame \(frameNumber)")
                .foregroundColor(.strikeGold)
                .font(.headline)

            HStack(spacing: 12) {
                // First shot
                Picker("1", selection: $frame.firstShot) {
                    ForEach(0...10, id: \.self) { pins in
                        Text(pins == 10 ? "X" : "\(pins)").tag(pins)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 70)
                .padding(8)
                .background(LinearGradient.cardSurfaceLight)
                .cornerRadius(8)

                // Second shot (if not strike or if 10th frame where second shot is allowed)
                if frame.firstShot < 10 || frameNumber == 10 {
                    let maxSecond = max(0, 10 - frame.firstShot)
                    Picker("2", selection: Binding(
                        get: { frame.secondShot ?? 0 },
                        set: { frame.secondShot = $0 }
                    )) {
                        ForEach(0...maxSecond, id: \.self) { pins in
                            Text(pins == maxSecond && frame.firstShot + pins == 10 ? "/" : "\(pins)").tag(pins)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 70)
                    .padding(8)
                    .background(LinearGradient.cardSurfaceLight)
                    .cornerRadius(8)
                }

                // Third shot for 10th frame
                if frameNumber == 10, frame.isStrike || frame.isSpare {
                    Picker("3", selection: Binding(
                        get: { frame.thirdShot ?? 0 },
                        set: { frame.thirdShot = $0 }
                    )) {
                        ForEach(0...10, id: \.self) { pins in
                            Text(pins == 10 ? "X" : "\(pins)").tag(pins)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 70)
                    .padding(8)
                    .background(LinearGradient.cardSurfaceLight)
                    .cornerRadius(8)
                }

                Spacer()

                Text(frame.displayValue)
                    .foregroundColor(frame.isStrike || frame.isSpare ? .strikeGold : .white)
                    .font(.title3)
                    .bold()
            }
        }
        .padding()
        .background(LinearGradient.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.strikeGold.opacity(0.2), lineWidth: 0.6)
        )
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
    }
}

