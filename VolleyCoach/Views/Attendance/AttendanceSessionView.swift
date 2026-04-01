import SwiftUI
import SwiftData

struct AttendanceSessionView: View {
    let group: TeamGroup
    var existingSession: AttendanceSession? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var statusMap: [PersistentIdentifier: AttendanceStatus] = [:]

    private var players: [Player] { group.players.sorted { $0.fullName < $1.fullName } }
    private var isEditing: Bool { existingSession != nil }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Session Date", selection: $date, displayedComponents: .date)
                }

                if !players.isEmpty {
                    Section {
                        HStack(spacing: 0) {
                            summaryCell(count: statusMap.values.filter { $0 == .present  }.count, label: "Present",  hex: "#34C759")
                            summaryCell(count: statusMap.values.filter { $0 == .absent   }.count, label: "Absent",   hex: "#FF3B30")
                            summaryCell(count: statusMap.values.filter { $0 == .late     }.count, label: "Late",     hex: "#FF9500")
                            summaryCell(count: statusMap.values.filter { $0 == .excused  }.count, label: "Excused",  hex: "#5AC8FA")
                        }
                    }
                }

                Section("Players (\(players.count))") {
                    if players.isEmpty {
                        Text("Add players to this group first.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(players) { player in
                            AttendancePlayerRow(
                                player: player,
                                status: Binding(
                                    get: { statusMap[player.persistentModelID] ?? .present },
                                    set: { statusMap[player.persistentModelID] = $0 }
                                )
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isEditing ? "Edit Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(players.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func summaryCell(count: Int, label: String, hex: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(Color(hex: hex))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func load() {
        if let s = existingSession {
            date = s.date
            for r in s.records {
                if let pid = r.player?.persistentModelID { statusMap[pid] = r.status }
            }
        }
        // Fill any missing players with default
        for p in players where statusMap[p.persistentModelID] == nil {
            statusMap[p.persistentModelID] = .present
        }
    }

    private func save() {
        let session: AttendanceSession
        if let existing = existingSession {
            session = existing
            session.date = date
            for r in session.records { modelContext.delete(r) }
            session.records = []
        } else {
            session = AttendanceSession(date: date)
            modelContext.insert(session)
            group.attendanceSessions.append(session)
        }

        for player in players {
            let status = statusMap[player.persistentModelID] ?? .present
            let record = AttendanceRecord(player: player, status: status)
            modelContext.insert(record)
            session.records.append(record)
        }

        dismiss()
    }
}

struct AttendancePlayerRow: View {
    let player: Player
    @Binding var status: AttendanceStatus

    var body: some View {
        HStack(spacing: 12) {
            PlayerPhotoView(photoData: player.photoData, name: player.fullName, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName).font(.body)
                if let n = player.jerseyNumber {
                    Text("#\(n)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

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
                Label(status.rawValue, systemImage: status.sfSymbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(hex: status.colorHex))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: status.colorHex).opacity(0.14), in: .capsule)
            }
        }
        .padding(.vertical, 2)
    }
}
