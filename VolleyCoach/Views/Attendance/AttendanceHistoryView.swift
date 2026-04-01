import SwiftUI
import SwiftData

struct AttendanceHistoryView: View {
    let group: TeamGroup
    @Environment(\.modelContext) private var modelContext

    @State private var showingNew = false
    @State private var sessionToEdit: AttendanceSession?

    private var sessions: [AttendanceSession] {
        group.attendanceSessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.plus",
                    title: "No Sessions Yet",
                    subtitle: "Start the first attendance session for \(group.name).",
                    buttonTitle: "Start Session",
                    action: { showingNew = true }
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        Button { sessionToEdit = session } label: {
                            SessionRow(session: session, totalPlayers: group.players.count)
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(session) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNew) { AttendanceSessionView(group: group) }
        .sheet(item: $sessionToEdit) { s in AttendanceSessionView(group: group, existingSession: s) }
    }

    private func delete(_ session: AttendanceSession) {
        group.attendanceSessions.removeAll { $0.persistentModelID == session.persistentModelID }
        modelContext.delete(session)
    }
}

struct SessionRow: View {
    let session: AttendanceSession
    let totalPlayers: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.date, style: .date).font(.headline)

                HStack(spacing: 10) {
                    badge(session.presentCount, status: .present)
                    badge(session.absentCount,  status: .absent)
                    if session.lateCount   > 0 { badge(session.lateCount,   status: .late) }
                    if session.excusedCount > 0 { badge(session.excusedCount, status: .excused) }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.presentCount)/\(totalPlayers)").font(.title3.bold())
                Text("present").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func badge(_ count: Int, status: AttendanceStatus) -> some View {
        HStack(spacing: 3) {
            Image(systemName: status.sfSymbol)
            Text("\(count)")
        }
        .font(.caption)
        .foregroundStyle(Color(hex: status.colorHex))
    }
}
