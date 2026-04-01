import SwiftUI
import SwiftData

struct PlayerListView: View {
    let group: TeamGroup
    @Environment(\.modelContext) private var modelContext

    @State private var search = ""
    @State private var sortByJersey = false
    @State private var showingAdd = false
    @State private var playerToEdit: Player?
    @State private var playerToDelete: Player?

    private var players: [Player] {
        group.players
            .filter { search.isEmpty || $0.fullName.localizedCaseInsensitiveContains(search) }
            .sorted {
                if sortByJersey {
                    return ($0.jerseyNumber ?? Int.max) < ($1.jerseyNumber ?? Int.max)
                }
                return $0.fullName < $1.fullName
            }
    }

    var body: some View {
        Group {
            if group.players.isEmpty {
                EmptyStateView(
                    systemImage: "person.badge.plus",
                    title: "No Players Yet",
                    subtitle: "Add your first player to \(group.name).",
                    buttonTitle: "Add Player",
                    action: { showingAdd = true }
                )
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
                .searchable(text: $search, prompt: "Search players")
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        sortByJersey = false
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Sort by Name", systemImage: !sortByJersey ? "checkmark" : "circle")
                    }
                    Button {
                        sortByJersey = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Sort by Jersey #", systemImage: sortByJersey ? "checkmark" : "circle")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }

                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddEditPlayerView(group: group) }
        .sheet(item: $playerToEdit) { p in AddEditPlayerView(group: group, player: p) }
        .alert(
            "Delete \"\(playerToDelete?.fullName ?? "")\"?",
            isPresented: Binding(get: { playerToDelete != nil }, set: { if !$0 { playerToDelete = nil } })
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
        for session in group.attendanceSessions {
            session.records.removeAll { $0.player?.persistentModelID == player.persistentModelID }
        }
        group.players.removeAll { $0.persistentModelID == player.persistentModelID }
        modelContext.delete(player)
        playerToDelete = nil
    }
}

struct PlayerRowView: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            PlayerPhotoView(photoData: player.photoData, name: player.fullName, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.body.weight(.medium))

                HStack(spacing: 8) {
                    if let n = player.jerseyNumber {
                        Text("#\(n)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if player.position != .unknown {
                        Text(player.position.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let age = player.age {
                Text("\(age)y")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
