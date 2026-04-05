import SwiftUI
import SwiftData

struct FeeOverviewView: View {
    let group: TeamGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allGroups: [TeamGroup]

    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var unpaidOnly = false
    @State private var showUnpaidSummary = true

    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    /// Every player across every group who hasn't paid for the current month/year.
    private var unpaidThisMonth: [(player: Player, group: TeamGroup)] {
        var results: [(Player, TeamGroup)] = []
        for g in allGroups {
            for p in g.players {
                let rec = p.feeRecords.first { $0.month == currentMonth && $0.year == currentYear }
                if rec?.status != .paid {
                    results.append((p, g))
                }
            }
        }
        return results.sorted { $0.0.fullName < $1.0.fullName }
    }

    private var visiblePlayers: [Player] {
        let sorted = group.players.sorted { $0.fullName < $1.fullName }
        guard unpaidOnly else { return sorted }
        return sorted.filter { player in
            let rec = player.feeRecords.first { $0.month == currentMonth && $0.year == year }
            return rec?.status != .paid
        }
    }

    private func markPaid(_ player: Player) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let rec = player.feeRecords.first(where: { $0.month == currentMonth && $0.year == currentYear }) {
            rec.status = .paid
            rec.paymentDate = Date()
        } else {
            let rec = FeeRecord(month: currentMonth, year: currentYear, status: .paid)
            rec.paymentDate = Date()
            modelContext.insert(rec)
            player.feeRecords.append(rec)
        }
    }

    private var unpaidPlayersInGroup: [Player] {
        group.players.filter { player in
            let rec = player.feeRecords.first { $0.month == currentMonth && $0.year == currentYear }
            return rec?.status != .paid
        }
    }

    private var expectedTotal: Double {
        Double(group.players.count) * group.monthlyFee
    }

    private var outstandingTotal: Double {
        Double(unpaidPlayersInGroup.count) * group.monthlyFee
    }

    private var collectedTotal: Double {
        expectedTotal - outstandingTotal
    }

    private func formatEuro(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "€\(Int(value))"
        }
        return String(format: "€%.2f", value)
    }

    private var paidCount: Int {
        group.players.filter { player in
            player.feeRecords.first { $0.month == currentMonth && $0.year == year }?.status == .paid
        }.count
    }

    private var groupCollectionCard: some View {
        let unpaidCount = unpaidPlayersInGroup.count
        let playerCount = group.players.count
        let monthLabel = FeeRecord.monthNames[currentMonth - 1]

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "eurosign.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("To Collect · \(monthLabel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.label))
                Spacer()
                Text("\(formatEuro(group.monthlyFee)) × player")
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formatEuro(outstandingTotal))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(outstandingTotal > 0 ? Color.orange : Color.green)
                Text("outstanding")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            HStack(spacing: 4) {
                Text("\(unpaidCount) of \(playerCount) unpaid")
                Text("·")
                Text("Collected \(formatEuro(collectedTotal)) of \(formatEuro(expectedTotal))")
            }
            .font(.caption)
            .foregroundStyle(Color(.secondaryLabel))

            GeometryReader { geo in
                let fraction = expectedTotal > 0 ? min(1, collectedTotal / expectedTotal) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(Color.green).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
    }

    var body: some View {
        Group {
            if group.players.isEmpty {
                ContentUnavailableView {
                    Label("No Players", systemImage: "creditcard")
                } description: {
                    Text("Add players to this group to start tracking fees.")
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Unpaid This Month (cross-group)
                        UnpaidThisMonthSection(
                            unpaid: unpaidThisMonth,
                            monthName: FeeRecord.monthNames[currentMonth - 1],
                            year: currentYear,
                            isExpanded: $showUnpaidSummary,
                            onMarkPaid: { player in markPaid(player) }
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        // Controls
                        HStack {
                            Picker("Year", selection: $year) {
                                ForEach((year - 2)...(year + 1), id: \.self) { y in
                                    Text(String(y)).tag(y)
                                }
                            }
                            .pickerStyle(.menu)

                            Spacer()

                            Toggle("Unpaid only", isOn: $unpaidOnly)
                                .toggleStyle(.button)
                                .tint(.red)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                        // Group collection card (only if monthlyFee set)
                        if group.monthlyFee > 0 {
                            groupCollectionCard
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                        }

                        // Month header row
                        HStack(spacing: 0) {
                            Text("Player")
                                .font(.caption2)
                                .foregroundStyle(Color(.secondaryLabel))
                                .frame(width: 120, alignment: .leading)
                                .padding(.leading, 4)
                            ForEach(FeeRecord.monthNames, id: \.self) { m in
                                Text(m)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 6)

                        // Player rows
                        VStack(spacing: 3) {
                            ForEach(visiblePlayers) { player in
                                FeePlayerRow(player: player, year: year, modelContext: modelContext)
                            }
                        }
                        .padding(.horizontal)

                        // Summary
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill")
                            Text("\(paidCount) of \(group.players.count) paid for \(FeeRecord.monthNames[currentMonth - 1])")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
}

struct FeePlayerRow: View {
    let player: Player
    let year: Int
    let modelContext: ModelContext

    private func record(for month: Int) -> FeeRecord? {
        player.feeRecords.first { $0.month == month && $0.year == year }
    }

    private func toggle(month: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let r = record(for: month) {
            r.status = r.status.next
        } else {
            let r = FeeRecord(month: month, year: year, status: .paid)
            modelContext.insert(r)
            player.feeRecords.append(r)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(player.fullName)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
                .padding(.leading, 4)

            ForEach(1...12, id: \.self) { m in
                let status = record(for: m)?.status ?? .unpaid
                Button { toggle(month: m) } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(status.color.opacity(0.85))
                        .frame(height: 22)
                        .overlay {
                            if status == .partial {
                                Text("P")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 1)
                .sensoryFeedback(.impact, trigger: status)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 8))
    }
}

// MARK: - UnpaidThisMonthSection

struct UnpaidThisMonthSection: View {
    let unpaid: [(player: Player, group: TeamGroup)]
    let monthName: String
    let year: Int
    @Binding var isExpanded: Bool
    let onMarkPaid: (Player) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: unpaid.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(unpaid.isEmpty ? .green : .orange)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Unpaid This Month")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(.label))
                        Text("\(monthName) \(String(year)) · all groups")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    Spacer()

                    Text("\(unpaid.count)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 32, minHeight: 28)
                        .padding(.horizontal, 8)
                        .background(
                            (unpaid.isEmpty ? Color.green : Color.red),
                            in: .capsule
                        )

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded && !unpaid.isEmpty {
                Divider().padding(.leading, 12)
                VStack(spacing: 0) {
                    ForEach(Array(unpaid.enumerated()), id: \.offset) { idx, entry in
                        UnpaidPlayerRow(
                            player: entry.player,
                            group: entry.group,
                            onMarkPaid: { onMarkPaid(entry.player) }
                        )
                        if idx < unpaid.count - 1 {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    (unpaid.isEmpty ? Color.green : Color.orange).opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

struct UnpaidPlayerRow: View {
    let player: Player
    let group: TeamGroup
    let onMarkPaid: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(player.fullName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(.label))
                HStack(spacing: 4) {
                    Text(group.emoji).font(.caption2)
                    Text(group.name)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }

            Spacer()

            Button(action: onMarkPaid) {
                Text("Mark Paid")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
