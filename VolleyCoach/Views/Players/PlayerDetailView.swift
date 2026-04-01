import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    let group: TeamGroup
    @State private var showingEdit = false

    private var attendanceRate: Double { group.attendancePercentage(for: player) }

    private var paidThisYear: Int {
        let year = Calendar.current.component(.year, from: Date())
        return player.feeRecords.filter { $0.year == year && $0.status == .paid }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                VStack(spacing: 12) {
                    PlayerPhotoView(photoData: player.photoData, name: player.fullName, size: 88)
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            if let n = player.jerseyNumber {
                                Text("#\(n)")
                                    .font(.title2.bold())
                                    .foregroundStyle(Color(hex: group.colorHex))
                            }
                            Text(player.fullName)
                                .font(.title2.bold())
                        }
                        if player.position != .unknown {
                            Label(player.position.rawValue, systemImage: player.position.sfSymbol)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Stats
                HStack(spacing: 0) {
                    statCell(
                        "Attendance",
                        String(format: "%.0f%%", attendanceRate),
                        color: attendanceRate >= 80 ? .green : attendanceRate >= 60 ? .orange : .red
                    )
                    Divider().frame(height: 40)
                    statCell("Paid (year)", "\(paidThisYear)/12", color: .blue)
                    if let age = player.age {
                        Divider().frame(height: 40)
                        statCell("Age", "\(age)", color: .purple)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                .padding(.horizontal)

                // Personal info
                card {
                    sectionHeader("Personal Info")
                    infoRow("Date of Birth",
                            player.dateOfBirth.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "—")

                    if !player.parentName.isEmpty {
                        divider()
                        infoRow("Parent / Guardian", player.parentName)
                    }
                    if !player.parentPhone.isEmpty {
                        divider()
                        phoneRow("Parent Phone", player.parentPhone)
                    }
                    if !player.notes.isEmpty {
                        divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(player.notes)
                                .font(.subheadline)
                        }
                        .padding()
                    }
                }

                // Attendance history
                card {
                    sectionHeader("Recent Attendance")
                    attendanceHistory
                }

                // Fee grid
                card {
                    sectionHeader("Fees — \(Calendar.current.component(.year, from: Date()))")
                    feeGrid
                }

                Spacer(minLength: 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditPlayerView(group: group, player: player)
        }
    }

    // MARK: Sub-views

    private var attendanceHistory: some View {
        let sessions = group.attendanceSessions.sorted { $0.date > $1.date }.prefix(10)

        return Group {
            if sessions.isEmpty {
                Text("No sessions recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(sessions)) { session in
                    let rec = session.records.first { $0.player?.persistentModelID == player.persistentModelID }
                    let s = rec?.status ?? .absent

                    HStack {
                        Text(session.date, style: .date)
                            .font(.subheadline)
                        Spacer()
                        Label(s.rawValue, systemImage: s.sfSymbol)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: s.colorHex))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if session.persistentModelID != sessions.last?.persistentModelID {
                        Divider().padding(.leading)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var feeGrid: some View {
        let year = Calendar.current.component(.year, from: Date())
        let byMonth: [Int: FeeRecord] = Dictionary(
            uniqueKeysWithValues: player.feeRecords
                .filter { $0.year == year }
                .map { ($0.month, $0) }
        )

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
            ForEach(1...12, id: \.self) { m in
                let status = byMonth[m]?.status ?? .unpaid
                VStack(spacing: 3) {
                    Text(FeeRecord.monthNames[m - 1])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Image(systemName: status.sfSymbol)
                        .font(.caption)
                        .foregroundStyle(Color(hex: status.colorHex))
                }
            }
        }
        .padding()
    }

    // MARK: Helpers

    private func statCell(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
            .padding(.horizontal)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline)
        }
        .padding()
    }

    private func phoneRow(_ label: String, _ number: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            if let url = URL(string: "tel:\(number.filter(\.isNumber))") {
                Link(number, destination: url).font(.subheadline)
            }
        }
        .padding()
    }

    private func divider() -> some View {
        Divider().padding(.leading)
    }
}
