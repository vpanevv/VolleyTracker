import SwiftUI
import SwiftData

struct GroupsListView: View {
    let coach: Coach
    @Environment(\.modelContext) private var modelContext

    @State private var showingAdd = false
    @State private var groupToEdit: TeamGroup?
    @State private var groupToDelete: TeamGroup?
    @State private var autoNavGroup: TeamGroup?

    private var groups: [TeamGroup] {
        coach.groups.sorted { $0.createdAt < $1.createdAt }
    }

    private var totalPlayers: Int {
        coach.groups.reduce(0) { $0 + $1.players.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                Group {
                    if groups.isEmpty {
                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.heroGradient.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 46, weight: .semibold))
                                    .heroGradientForeground()
                            }
                            Text("No groups yet")
                                .font(.title2.weight(.bold))
                            Text("Tap + to create your first group and let's get started.")
                                .font(.subheadline)
                                .foregroundStyle(Color(.secondaryLabel))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        List {
                            Section {
                                AIGreetingHeader(coachName: coach.name,
                                                 groupCount: groups.count,
                                                 playerCount: totalPlayers)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }

                            Section {
                                ForEach(groups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupRowView(group: group)
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
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
                            } header: {
                                Text("Your Teams")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .textCase(nil)
                            }
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .heroGradientForeground()
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddEditGroupView(coach: coach) }
            .sheet(item: $groupToEdit) { g in AddEditGroupView(coach: coach, group: g) }
            .navigationDestination(item: $autoNavGroup) { g in
                GroupDetailView(group: g)
            }
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("--open-fees"),
                   autoNavGroup == nil,
                   let first = groups.first {
                    autoNavGroup = first
                }
            }
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

// MARK: - AI Greeting Header

struct AIGreetingHeader: View {
    let coachName: String
    let groupCount: Int
    let playerCount: Int

    @State private var now = Date()
    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var firstName: String {
        coachName.split(separator: " ").first.map(String.init) ?? "Coach"
    }

    private var weekdayText: String {
        now.formatted(.dateTime.weekday(.wide))
    }

    private var dateText: String {
        now.formatted(.dateTime.day().month(.wide).year())
    }

    private var timeText: String {
        now.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AppTheme.heroGradient.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .heroGradientForeground()
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(weekdayText.uppercased()) · \(dateText.uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .heroGradientForeground()
                    Text(timeText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(.label))
                        .monospacedDigit()
                }

                Spacer()

                Circle()
                    .fill(AppTheme.heroGradient)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.6),
                            radius: 6, x: 0, y: 0)
            }
            .onReceive(ticker) { now = $0 }

            Text("\(Greeting.forNow()),\n\(firstName) 👋")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(.label), Color(.label).opacity(0.75)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .lineSpacing(2)

            HStack(spacing: 10) {
                StatPill(icon: "person.3.fill",
                         value: "\(groupCount)",
                         label: groupCount == 1 ? "group" : "groups",
                         tint: Color(red: 0.24, green: 0.40, blue: 1.00))
                StatPill(icon: "figure.volleyball",
                         value: "\(playerCount)",
                         label: playerCount == 1 ? "player" : "players",
                         tint: Color(red: 0.90, green: 0.30, blue: 0.70))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.12),
                radius: 24, x: 0, y: 12)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.caption)
                .opacity(0.85)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 1))
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
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                hexToColor(group.colorHex).opacity(0.35),
                                hexToColor(group.colorHex).opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(hexToColor(group.colorHex).opacity(0.4), lineWidth: 1)
                    )
                Text(group.emoji)
                    .font(.system(size: 30))
            }

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

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(hexToColor(group.colorHex).opacity(0.25), lineWidth: 1)
        )
        .shadow(color: hexToColor(group.colorHex).opacity(0.12), radius: 14, x: 0, y: 8)
    }
}
