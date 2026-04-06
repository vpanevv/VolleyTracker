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

    private var groupColor: Color { hexToColor(group.colorHex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                VStack(spacing: 12) {
                    PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 88, color: groupColor)
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            if let n = player.jerseyNumber {
                                Text("#\(n)")
                                    .font(.title2.bold())
                                    .foregroundStyle(AppTheme.courtBlueLite)
                            }
                            Text(player.fullName)
                                .font(.title2.bold())
                                .foregroundStyle(Color(.label))
                        }
                        if player.position != .unknown {
                            Label(player.position.rawValue, systemImage: player.position.sfSymbol)
                                .font(.subheadline)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }

                // Stats strip
                HStack(spacing: 0) {
                    statCell("Attendance", String(format: "%.0f%%", attendanceRate),
                             color: attendanceRate >= 80 ? AppTheme.successGreen : attendanceRate >= 60 ? AppTheme.warningAmber : AppTheme.dangerRed)
                    Divider().frame(height: 40)
                    statCell("Paid (year)", "\(paidThisYear)/12", color: AppTheme.courtBlueLite)
                    if let age = player.age {
                        Divider().frame(height: 40)
                        statCell("Age", "\(age)", color: Color(.secondaryLabel))
                    }
                }
                .padding()
                .background(AppTheme.cardSurface, in: .rect(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                .padding(.horizontal)

                // Personal info card
                infoCard {
                    cardHeader("Personal Info")
                    infoRow("Date of Birth",
                            player.dateOfBirth.map {
                                DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none)
                            } ?? "—")

                    if !player.parentName.isEmpty {
                        Divider().padding(.leading)
                        infoRow("Parent / Guardian", player.parentName)
                    }
                    if !player.parentPhone.isEmpty {
                        Divider().padding(.leading)
                        phoneRow("Parent Phone", player.parentPhone)
                    }
                    if !player.notes.isEmpty {
                        Divider().padding(.leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(Color(.secondaryLabel))
                            Text(player.notes)
                                .font(.subheadline)
                                .foregroundStyle(Color(.label))
                        }
                        .padding()
                    }
                }

                // Attendance history card
                infoCard {
                    cardHeader("Recent Attendance")
                    attendanceHistory
                }

                // Fee grid card
                infoCard {
                    cardHeader("Fees — \(Calendar.current.component(.year, from: Date()))")
                    feeGrid
                }

                Spacer(minLength: 32)
            }
        }
        .background(AppTheme.skyBlue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditPlayerView(group: group, player: player)
        }
    }

    // MARK: - Attendance

    private var attendanceHistory: some View {
        let sessions = group.trainingSessions
            .filter { $0.attendanceTaken }
            .sorted { $0.date > $1.date }
            .prefix(10)

        return Group {
            if sessions.isEmpty {
                Text("No attendance recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding()
            } else {
                ForEach(Array(sessions)) { session in
                    let rec = session.attendanceRecords.first {
                        $0.player?.persistentModelID == player.persistentModelID
                    }
                    let s = rec?.status ?? .absent
                    HStack {
                        Text(session.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Label(s.rawValue, systemImage: s.sfSymbol)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(s.color)
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

    // MARK: - Fee Grid

    private var feeGrid: some View {
        let year = Calendar.current.component(.year, from: Date())
        let byMonth = Dictionary(
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
                        .foregroundStyle(Color(.secondaryLabel))
                    Image(systemName: status.sfSymbol)
                        .font(.caption)
                        .foregroundStyle(status.color)
                }
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func statCell(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(Color(.secondaryLabel)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func infoCard<C: View>(@ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .background(AppTheme.cardSurface, in: .rect(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
            .padding(.horizontal)
    }

    private func cardHeader(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppTheme.courtBlueLite)
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Color(.secondaryLabel))
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(Color(.label))
        }
        .padding()
    }

    private func phoneRow(_ label: String, _ number: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Color(.secondaryLabel))
            Spacer()
            if let url = URL(string: "tel:\(number.filter(\.isNumber))") {
                Link(number, destination: url)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.activeBlue)
            }
        }
        .padding()
    }
}
