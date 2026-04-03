import SwiftUI
import SwiftData

struct PlayerListView: View {
    let group: TeamGroup
    let searchText: String
    @Environment(\.modelContext) private var modelContext

    @State private var sortByJersey = false
    @State private var showingAdd = false
    @State private var playerToEdit: Player?
    @State private var playerToDelete: Player?

    private var players: [Player] {
        group.players
            .filter { searchText.isEmpty || $0.fullName.localizedCaseInsensitiveContains(searchText) }
            .sorted {
                sortByJersey
                    ? ($0.jerseyNumber ?? Int.max) < ($1.jerseyNumber ?? Int.max)
                    : $0.fullName < $1.fullName
            }
    }

    var body: some View {
        Group {
            if group.players.isEmpty {
                ContentUnavailableView {
                    Label("No Players Yet", systemImage: "person.badge.plus")
                } description: {
                    Text("Add your first player to \(group.name).")
                } actions: {
                    Button("Add Player") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
            } else {
                List {
                    ForEach(players) { player in
                        NavigationLink(destination: PlayerDetailView(player: player, group: group)) {
                            PlayerRowView(player: player)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { playerToDelete = player } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { playerToEdit = player } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        sortByJersey = false
                    } label: {
                        Label("Sort by Name",
                              systemImage: !sortByJersey ? "checkmark" : "circle")
                    }
                    Button {
                        sortByJersey = true
                    } label: {
                        Label("Sort by Jersey #",
                              systemImage: sortByJersey ? "checkmark" : "circle")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }

                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { AddEditPlayerView(group: group) }
        .sheet(item: $playerToEdit) { p in AddEditPlayerView(group: group, player: p) }
        .alert(
            "Delete \"\(playerToDelete?.fullName ?? "")\"?",
            isPresented: Binding(
                get: { playerToDelete != nil },
                set: { if !$0 { playerToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { playerToDelete = nil }
            Button("Delete", role: .destructive) {
                if let p = playerToDelete { delete(p) }
            }
        } message: {
            Text("All attendance and fee records for this player will be permanently deleted.")
        }
    }

    private func delete(_ player: Player) {
        // Clean up attendance records in all training sessions
        for session in group.trainingSessions {
            session.attendanceRecords.removeAll {
                $0.player?.persistentModelID == player.persistentModelID
            }
        }
        group.players.removeAll { $0.persistentModelID == player.persistentModelID }
        modelContext.delete(player)
        playerToDelete = nil
    }
}

// MARK: - PlayerRowView

struct PlayerRowView: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(player.fullName)
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                HStack(spacing: 6) {
                    if let n = player.jerseyNumber {
                        Text("#\(n)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue, in: .capsule)
                    }
                    if player.position != .unknown {
                        Text(player.position.rawValue)
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }

            Spacer()

            if let age = player.age {
                Text("\(age)y")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 2)
    }
}
