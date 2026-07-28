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
                CourtRosterEmptyState(groupName: group.name) { showingAdd = true }
            } else {
                List {
                    ForEach(players) { player in
                        NavigationLink(destination: PlayerDetailView(player: player, group: group)) {
                            PlayerRowView(
                                player: player,
                                tint: Color(teamHex: group.colorHex)
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { playerToDelete = player } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { playerToEdit = player } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(AppTheme.ocean)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
        let remoteID = player.remoteID
        // Clean up attendance records in all training sessions
        for session in group.trainingSessions {
            session.attendanceRecords.removeAll {
                $0.player?.persistentModelID == player.persistentModelID
            }
        }
        group.players.removeAll { $0.persistentModelID == player.persistentModelID }
        modelContext.delete(player)
        Task { try? await CloudDataService.shared.delete(table: "players", id: remoteID) }
        playerToDelete = nil
    }
}

private struct CourtRosterEmptyState: View {
    let groupName: String
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.heroGradient)
                    .frame(width: 94, height: 94)
                    .blur(radius: 22)
                    .opacity(0.16)
                CourtIconBadge(icon: "person.badge.plus", tint: AppTheme.ocean, size: 74)
            }

            VStack(spacing: 6) {
                Text("Build the roster")
                    .font(.title3.weight(.bold))
                Text("Add your first player to \(groupName), then track attendance, positions and fees.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                Label("Add First Player", systemImage: "plus")
            }
            .buttonStyle(CourtPrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: 350)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.ocean.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.10), radius: 20, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 22)
        .padding(.bottom, 70)
    }
}

// MARK: - PlayerRowView

struct PlayerRowView: View {
    let player: Player
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 44)
                .overlay(Circle().strokeBorder(tint.opacity(0.65), lineWidth: 2))

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
                            .background(tint, in: .capsule)
                    }
                    if player.position != .unknown {
                        Text(LocalizedStringKey(player.position.rawValue))
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
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.08), radius: 10, y: 5)
    }
}
