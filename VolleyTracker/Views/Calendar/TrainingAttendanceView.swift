import SwiftUI
import SwiftData

struct TrainingAttendanceView: View {
    let session: TrainingSession
    @Environment(\.modelContext) private var modelContext

    @State private var statusMap: [PersistentIdentifier: AttendanceStatus] = [:]
    @State private var isDirty = false
    @State private var quickMode = false

    private var group: TeamGroup? { session.group }
    private var players: [Player] { group?.players.sorted { $0.fullName < $1.fullName } ?? [] }

    var body: some View {
        Group {
            if quickMode {
                quickModeView
            } else {
                detailListView
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        quickMode.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Label(
                        quickMode ? "Detail" : "Quick",
                        systemImage: quickMode ? "list.bullet" : "bolt.fill"
                    )
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!isDirty && session.attendanceTaken)
            }
        }
        .onAppear(perform: load)
    }

    // MARK: - Quick Mode

    private var quickModeView: some View {
        ScrollView {
            // Summary strip (compact)
            HStack(spacing: 0) {
                summaryCell("Present", count: statusMap.values.filter { $0 == .present }.count, color: .blue)
                summaryCell("Absent",  count: statusMap.values.filter { $0 != .present }.count, color: Color(.secondaryLabel))
            }
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))

            if players.isEmpty {
                Text("No players in this group.")
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.top, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(players) { player in
                        QuickAttendanceRow(
                            player: player,
                            isPresent: (statusMap[player.persistentModelID] ?? .present) == .present
                        ) {
                            let current = statusMap[player.persistentModelID] ?? .present
                            statusMap[player.persistentModelID] = (current == .present) ? .absent : .present
                            isDirty = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var detailListView: some View {
        List {
            // Summary
            if !statusMap.isEmpty {
                Section {
                    HStack(spacing: 0) {
                        summaryCell("Present", count: statusMap.values.filter { $0 == .present }.count, color: .green)
                        summaryCell("Absent",  count: statusMap.values.filter { $0 == .absent  }.count, color: .red)
                        summaryCell("Late",    count: statusMap.values.filter { $0 == .late    }.count, color: .orange)
                        summaryCell("Excused", count: statusMap.values.filter { $0 == .excused }.count, color: .blue)
                    }
                }
            }

            // Players
            Section {
                if players.isEmpty {
                    Text("No players in this group.")
                        .foregroundStyle(Color(.secondaryLabel))
                } else {
                    ForEach(players) { player in
                        AttendancePlayerRow(
                            player: player,
                            status: Binding(
                                get: { statusMap[player.persistentModelID] ?? .present },
                                set: { newVal in
                                    statusMap[player.persistentModelID] = newVal
                                    isDirty = true
                                }
                            )
                        )
                    }
                }
            }

            // Mark All Present shortcut
            if !players.isEmpty {
                Section {
                    Button("Mark All Present") { markAll(.present) }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Sub-views

    private func summaryCell(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logic

    private var navTitle: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let date = fmt.string(from: session.date)
        return "\(group?.name ?? "Session") — \(date)"
    }

    private func load() {
        // Pre-populate from existing records
        for r in session.attendanceRecords {
            if let pid = r.player?.persistentModelID {
                statusMap[pid] = r.status
            }
        }
        // Fill any new players with .present
        for p in players where statusMap[p.persistentModelID] == nil {
            statusMap[p.persistentModelID] = .present
        }
    }

    private func markAll(_ status: AttendanceStatus) {
        for p in players { statusMap[p.persistentModelID] = status }
        isDirty = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func save() {
        // Remove old records
        for r in session.attendanceRecords { modelContext.delete(r) }
        session.attendanceRecords = []

        for player in players {
            let status = statusMap[player.persistentModelID] ?? .present
            let record = AttendanceRecord(player: player, status: status)
            modelContext.insert(record)
            session.attendanceRecords.append(record)
        }
        isDirty = false
    }
}

// MARK: - AttendancePlayerRow

struct AttendancePlayerRow: View {
    let player: Player
    @Binding var status: AttendanceStatus

    var body: some View {
        HStack(spacing: 12) {
            // Tap to toggle present ↔ absent
            Button {
                let next: AttendanceStatus = status == .present ? .absent : .present
                status = next
            } label: {
                Image(systemName: status == .present ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(status == .present ? .blue : Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact, trigger: status)

            PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.body)
                    .foregroundStyle(Color(.label))
                if let n = player.jerseyNumber {
                    Text("#\(n)")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }

            Spacer()

            // Long-press / context menu for late / excused
            Menu {
                ForEach(AttendanceStatus.allCases, id: \.self) { s in
                    Button {
                        status = s
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label(s.rawValue, systemImage: s.sfSymbol)
                    }
                }
            } label: {
                if status == .late || status == .excused {
                    Label(status.rawValue, systemImage: status.sfSymbol)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.12), in: .capsule)
                } else {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - QuickAttendanceRow

struct QuickAttendanceRow: View {
    let player: Player
    let isPresent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isPresent ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(isPresent ? .white : Color(.tertiaryLabel))

                Text(player.fullName)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(isPresent ? .white : Color(.label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if let n = player.jerseyNumber {
                    Text("#\(n)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isPresent ? .white.opacity(0.85) : Color(.secondaryLabel))
                }
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                isPresent ? Color.blue : Color(.secondarySystemGroupedBackground),
                in: .rect(cornerRadius: 14)
            )
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isPresent)
    }
}
