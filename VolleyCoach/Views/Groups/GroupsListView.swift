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
                    EmptyStateView(
                        systemImage: "person.3.fill",
                        title: "No Groups Yet",
                        subtitle: "Create your first team to start tracking players, attendance, and fees.",
                        buttonTitle: "Add First Group",
                        action: { showingAdd = true }
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160), spacing: 16)],
                            spacing: 16
                        ) {
                            ForEach(groups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupCardView(group: group)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Edit") { groupToEdit = group }
                                    Button("Delete", role: .destructive) { groupToDelete = group }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("VolleyCoach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditGroupView(coach: coach)
            }
            .sheet(item: $groupToEdit) { g in
                AddEditGroupView(coach: coach, group: g)
            }
            .alert(
                "Delete \"\(groupToDelete?.name ?? "")\"?",
                isPresented: Binding(get: { groupToDelete != nil }, set: { if !$0 { groupToDelete = nil } })
            ) {
                Button("Cancel", role: .cancel) { groupToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let g = groupToDelete { delete(g) }
                }
            } message: {
                Text("All players, attendance records, and fee data in this group will be permanently deleted.")
            }
        }
    }

    private func delete(_ group: TeamGroup) {
        coach.groups.removeAll { $0.persistentModelID == group.persistentModelID }
        modelContext.delete(group)
        groupToDelete = nil
    }
}
