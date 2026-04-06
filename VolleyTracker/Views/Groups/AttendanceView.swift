import SwiftUI
import SwiftData

// MARK: - AttendanceView (Attendance tab within GroupDetailView)

struct AttendanceView: View {
    let group: TeamGroup
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddTraining = false
    @State private var sessionToEdit: TrainingSession?

    private var sessions: [TrainingSession] {
        group.trainingSessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView {
                    Label("No Sessions Yet", systemImage: "calendar.badge.plus")
                } description: {
                    Text("Start your first training session for \(group.name).")
                } actions: {
                    Button("Start Session") { showingAddTraining = true }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.activeBlue)
                }
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: TrainingAttendanceView(session: session)) {
                            SessionRowView(session: session, totalPlayers: group.players.count)
                        }
                        .listRowBackground(AppTheme.cardSurface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(session) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddTraining = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTraining) {
            AddTrainingView(groups: [group], preselectedGroup: group)
        }
    }

    private func delete(_ session: TrainingSession) {
        group.trainingSessions.removeAll { $0.persistentModelID == session.persistentModelID }
        modelContext.delete(session)
    }
}

struct SessionRowView: View {
    let session: TrainingSession
    let totalPlayers: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date, style: .date)
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                HStack(spacing: 4) {
                    Text(session.timeRange)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))

                    if session.attendanceTaken {
                        Spacer()
                        statusBadge(session.presentCount, status: .present)
                        statusBadge(session.absentCount,  status: .absent)
                        if session.lateCount > 0    { statusBadge(session.lateCount,    status: .late) }
                        if session.excusedCount > 0 { statusBadge(session.excusedCount, status: .excused) }
                    }
                }
            }

            Spacer()

            if session.attendanceTaken {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.presentCount)/\(totalPlayers)")
                        .font(.title3.bold())
                        .foregroundStyle(Color(.label))
                    Text("present")
                        .font(.caption2)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            } else {
                Text("No attendance")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ count: Int, status: AttendanceStatus) -> some View {
        HStack(spacing: 2) {
            Image(systemName: status.sfSymbol)
            Text("\(count)")
        }
        .font(.caption)
        .foregroundStyle(status.color)
    }
}
