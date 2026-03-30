import SwiftUI

struct LocationsView: View {
    @ObservedObject var viewModel: StrikeZoneViewModel
    @State private var showingAdd = false
    @State private var editingLocation: Location?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Places")
                        .foregroundStyle(LinearGradient.goldAccent)
                        .font(.title2)
                        .bold()
                        .shadow(color: Color.strikeGold.opacity(0.3), radius: 4, x: 0, y: 1)

                    if viewModel.locations.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Text("No places yet")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text("Add bowling centers to pick them when logging a game.")
                                .foregroundColor(.strikeGray)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.locations) { loc in
                                Button {
                                    editingLocation = loc
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(LinearGradient.goldAccent)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(loc.name)
                                                .foregroundColor(.white)
                                                .font(.headline)
                                            if let addr = loc.address, !addr.isEmpty {
                                                Text(addr)
                                                    .foregroundColor(.strikeGray)
                                                    .font(.caption)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(LinearGradient.cardSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(LinearGradient.goldStroke, lineWidth: 0.8)
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteLocation(loc)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }

                    Button {
                        showingAdd = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(LinearGradient.goldAccent)
                            Text("Add place")
                                .foregroundColor(.strikeGold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.cardSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LinearGradient.goldStroke, lineWidth: 1.2)
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.strikeGold.opacity(0.2), radius: 4, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Places")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAdd) {
                LocationEditView(viewModel: viewModel, location: nil)
            }
            .sheet(item: $editingLocation) { loc in
                LocationEditView(viewModel: viewModel, location: loc)
            }
        }
    }
}

struct LocationEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StrikeZoneViewModel
    let location: Location?

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.screenBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .foregroundColor(.strikeGold)
                            .font(.caption)
                        TextField("Bowling center name", text: $name)
                            .textInputAutocapitalization(.words)
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address (optional)")
                            .foregroundColor(.strikeGold)
                            .font(.caption)
                        TextField("Address", text: $address)
                            .textInputAutocapitalization(.words)
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

                    if location != nil {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete place")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle(location == nil ? "Add place" : "Edit place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.strikeGray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(.strikeGold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let loc = location {
                    name = loc.name
                    address = loc.address ?? ""
                }
            }
            .alert("Delete place", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePlace()
                }
            } message: {
                Text("Are you sure you want to delete this place?")
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        let a = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if let loc = location {
            viewModel.updateLocation(Location(id: loc.id, name: n, address: a.isEmpty ? nil : a))
        } else {
            viewModel.addLocation(name: n, address: a.isEmpty ? nil : a)
        }
        dismiss()
    }

    private func deletePlace() {
        guard let loc = location else { return }
        viewModel.deleteLocation(loc)
        dismiss()
    }
}
