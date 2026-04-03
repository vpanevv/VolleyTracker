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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { groupToDelete = group } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { groupToEdit = group } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
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
                }
            }
            .navigationTitle("Groups")
            .toolbarBackground(.visible, for: .navigationBar)
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

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: group.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.12), in: .rect(cornerRadius: 10))

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
