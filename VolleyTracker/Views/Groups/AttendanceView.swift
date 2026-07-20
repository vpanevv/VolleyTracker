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
                VStack(spacing: 18) {
                    CourtIconBadge(icon: "checkmark.circle.fill", tint: AppTheme.success, size: 70)
                    VStack(spacing: 6) {
                        Text("Attendance starts here")
                            .font(.title3.weight(.bold))
                        Text("Create a session for \(group.name) and mark the roster in quick mode.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Button { showingAddTraining = true } label: {
                        Label("Start First Session", systemImage: "plus")
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
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: TrainingAttendanceView(session: session)) {
                            SessionRowView(session: session, totalPlayers: group.players.count)
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(session) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
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
        let remoteID = session.remoteID
        group.trainingSessions.removeAll { $0.persistentModelID == session.persistentModelID }
        modelContext.delete(session)
        Task { try? await CloudDataService.shared.delete(table: "training_sessions", id: remoteID) }
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
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(AppTheme.ocean.opacity(0.14), lineWidth: 1)
        )
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
