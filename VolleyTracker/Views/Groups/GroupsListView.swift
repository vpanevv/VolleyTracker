import SwiftUI
import SwiftData

struct GroupsListView: View {
    let coach: Coach
    @Environment(\.modelContext) private var modelContext

    @State private var showingAdd = false
    @State private var groupToEdit: TeamGroup?
    @State private var groupToDelete: TeamGroup?

    private var groups: [TeamGroup] {
        coach.groups.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    ContentUnavailableView {
                        Label("No Groups Yet", systemImage: "sportscourt.fill")
                    } description: {
                        Text("Tap + to create your first group.")
                    }
                } else {
                    List {
                        ForEach(groups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupRowView(group: group)
                            }
                            .listRowBackground(AppTheme.cardSurface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { groupToDelete = group } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { groupToEdit = group } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppTheme.activeBlue)
                            }
                            .contextMenu {
                                Button { groupToEdit = group } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) { groupToDelete = group } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.skyBlue)
            .navigationTitle("Groups")
            .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddEditGroupView(coach: coach) }
            .sheet(item: $groupToEdit) { g in AddEditGroupView(coach: coach, group: g) }
            .alert(
                "Delete \"\(groupToDelete?.name ?? "")\"?",
                isPresented: Binding(
                    get: { groupToDelete != nil },
                    set: { if !$0 { groupToDelete = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { groupToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let g = groupToDelete { delete(g) }
                }
            } message: {
                Text("All players, training sessions, and fee data in this group will be permanently deleted.")
            }
        }
    }

    private func delete(_ group: TeamGroup) {
        coach.groups.removeAll { $0.persistentModelID == group.persistentModelID }
        modelContext.delete(group)
        groupToDelete = nil
    }
}

// MARK: - GroupRowView

struct GroupRowView: View {
    let group: TeamGroup

    private func hexToColor(_ hex: String) -> Color {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        return Color(
            red:   Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >>  8) / 255,
            blue:  Double( rgb & 0x0000FF       ) / 255
        )
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(group.emoji)
                .font(.system(size: 32))
                .frame(width: 44, height: 44)
                .background(hexToColor(group.colorHex).opacity(0.15), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                HStack(spacing: 6) {
                    Text("\(group.players.count) player\(group.players.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))

                    if !group.ageCategory.isEmpty {
                        Text("·")
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text(group.ageCategory)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
