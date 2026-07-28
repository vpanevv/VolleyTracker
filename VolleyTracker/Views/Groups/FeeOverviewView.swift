import SwiftUI
import SwiftData

struct FeeOverviewView: View {
    let group: TeamGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @AppStorage(AppCurrency.storageKey) private var currencyCode = AppCurrency.eur.rawValue

    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var unpaidOnly = false
    @State private var showUnpaidSummary = true
    @State private var exportedPDFURL: URL?
    @State private var exportError: String?

    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    /// Players in THIS group who haven't paid for the current month/year.
    private var unpaidThisMonth: [Player] {
        group.players
            .filter { player in
                let rec = player.feeRecords.first { $0.month == currentMonth && $0.year == currentYear }
                return rec?.status != .paid
            }
            .sorted { $0.fullName < $1.fullName }
    }

    private var visiblePlayers: [Player] {
        let sorted = group.players.sorted { $0.fullName < $1.fullName }
        guard unpaidOnly else { return sorted }
        return sorted.filter { player in
            let rec = player.feeRecords.first { $0.month == currentMonth && $0.year == year }
            return rec?.status != .paid
        }
    }

    private func exportPDF() {
        do {
            let url = try FeeReportPDF.generate(for: group)
            exportedPDFURL = url
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func markPaid(_ player: Player) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let savedRecord = paidRecord(for: player)
        Task { try? await CloudDataService.shared.upsertFee(savedRecord, playerID: player.remoteID) }
    }

    private func markVisiblePlayersPaid() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let fees = visiblePlayers.map { player in
            (fee: paidRecord(for: player), playerID: player.remoteID)
        }
        Task { try? await CloudDataService.shared.upsertFees(fees) }
    }

    private func paidRecord(for player: Player) -> FeeRecord {
        if let rec = player.feeRecords.first(where: { $0.month == currentMonth && $0.year == currentYear }) {
            rec.status = .paid
            rec.paymentDate = Date()
            return rec
        }

        let rec = FeeRecord(month: currentMonth, year: currentYear, status: .paid)
        rec.paymentDate = Date()
        rec.amount = group.monthlyFee > 0 ? group.monthlyFee : nil
        modelContext.insert(rec)
        player.feeRecords.append(rec)
        return rec
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
        (AppCurrency(rawValue: currencyCode) ?? .eur).format(value, locale: locale)
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
                Image(systemName: "banknote.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.ocean)
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
                    .foregroundStyle(outstandingTotal > 0 ? AppTheme.coral : AppTheme.success)
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
                    Capsule().fill(AppTheme.success).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppTheme.ocean.opacity(0.16), lineWidth: 1)
        )
    }

    var body: some View {
        Group {
            if group.players.isEmpty {
                VStack(spacing: 18) {
                    CourtIconBadge(icon: "creditcard", tint: AppTheme.ocean, size: 74)
                    VStack(spacing: 6) {
                        Text("Fees need a roster")
                            .font(.title3.weight(.bold))
                        Text("Add players to this group, then monthly fee tracking will appear here automatically.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
                .frame(maxWidth: 350)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.ocean.opacity(0.15), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 22)
                .padding(.bottom, 70)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Button(action: exportPDF) {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(CourtSecondaryButtonStyle())

                            Button(action: markVisiblePlayersPaid) {
                                Label("Mark Visible Paid", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(CourtPrimaryButtonStyle())
                            .disabled(visiblePlayers.isEmpty)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        // Unpaid This Month (this group only)
                        UnpaidThisMonthSection(
                            unpaid: unpaidThisMonth,
                            groupName: group.name,
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

                        CourtSectionLabel("Player Fees", subtitle: "Current month first. Open a card to adjust older months.")
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        VStack(spacing: 12) {
                            if visiblePlayers.isEmpty {
                                Text("No players match this filter.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
                            } else {
                                ForEach(visiblePlayers) { player in
                                    FeePlayerCard(
                                        player: player,
                                        year: year,
                                        currentMonth: currentMonth,
                                        monthlyFee: group.monthlyFee,
                                        modelContext: modelContext
                                    )
                                }
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
                        .background(.regularMaterial, in: .rect(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { exportedPDFURL.map { IdentifiedURL(url: $0) } },
            set: { exportedPDFURL = $0?.url }
        )) { wrapper in
            ShareSheet(items: [wrapper.url])
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }
}

private struct IdentifiedURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct FeePlayerCard: View {
    let player: Player
    let year: Int
    let currentMonth: Int
    let monthlyFee: Double
    let modelContext: ModelContext

    @State private var isExpanded = false
    @Environment(\.locale) private var locale
    @AppStorage(AppCurrency.storageKey) private var currencyCode = AppCurrency.eur.rawValue

    private var currentStatus: FeeStatus {
        record(for: currentMonth)?.status ?? .unpaid
    }

    private var paidMonthsCount: Int {
        (1...12).filter { record(for: $0)?.status == .paid }.count
    }

    private var amountText: String? {
        guard monthlyFee > 0 else { return nil }
        return (AppCurrency(rawValue: currencyCode) ?? .eur)
            .format(monthlyFee, locale: locale)
    }

    private func record(for month: Int) -> FeeRecord? {
        player.feeRecords.first { $0.month == month && $0.year == year }
    }

    private func set(month: Int, status: FeeStatus) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let savedRecord: FeeRecord
        if let record = record(for: month) {
            record.status = status
            record.paymentDate = status == .paid ? Date() : nil
            savedRecord = record
        } else {
            let record = FeeRecord(month: month, year: year, status: status)
            record.paymentDate = status == .paid ? Date() : nil
            record.amount = monthlyFee > 0 ? monthlyFee : nil
            modelContext.insert(record)
            player.feeRecords.append(record)
            savedRecord = record
        }
        Task { try? await CloudDataService.shared.upsertFee(savedRecord, playerID: player.remoteID) }
    }

    private func cycle(month: Int) {
        set(month: month, status: (record(for: month)?.status ?? .unpaid).next)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(player.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text("\(paidMonthsCount)/12 paid")
                        if let amountText {
                            Text("·")
                            Text(amountText)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                FeeStatusBadge(status: currentStatus, monthName: FeeRecord.monthNames[currentMonth - 1])
            }

            HStack(spacing: 10) {
                Button {
                    set(month: currentMonth, status: .paid)
                } label: {
                    Label("Mark \(FeeRecord.monthNames[currentMonth - 1]) Paid", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(CourtPrimaryButtonStyle())
                .disabled(currentStatus == .paid)

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.deepBlue)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.deepBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Hide monthly fee history" : "Show monthly fee history")
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Monthly Status")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(1...12, id: \.self) { month in
                            let status = record(for: month)?.status ?? .unpaid
                            FeeMonthButton(
                                monthName: FeeRecord.monthNames[month - 1],
                                status: status,
                                isCurrentMonth: month == currentMonth,
                                action: { cycle(month: month) }
                            )
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.ocean.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(currentStatus.color.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct FeeStatusBadge: View {
    let status: FeeStatus
    let monthName: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(LocalizedStringKey(monthName))
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Label(LocalizedStringKey(status.rawValue), systemImage: status.sfSymbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(status.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(status.color.opacity(0.13), in: Capsule())
        }
    }
}

private struct FeeMonthButton: View {
    let monthName: String
    let status: FeeStatus
    let isCurrentMonth: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: status.sfSymbol)
                    .font(.caption.weight(.bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(LocalizedStringKey(monthName))
                        .font(.caption.weight(.bold))
                    Text(LocalizedStringKey(status.rawValue))
                        .font(.system(size: 10, weight: .semibold))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(status == .unpaid ? status.color : .white)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(
                status == .unpaid ? status.color.opacity(0.12) : status.color,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isCurrentMonth ? AppTheme.deepBlue.opacity(0.55) : status.color.opacity(0.22), lineWidth: isCurrentMonth ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(monthName) \(status.rawValue)")
    }
}

// MARK: - UnpaidThisMonthSection

struct UnpaidThisMonthSection: View {
    let unpaid: [Player]
    let groupName: String
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
                        .foregroundStyle(unpaid.isEmpty ? AppTheme.success : AppTheme.coral)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Unpaid This Month")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(.label))
                        Text("\(monthName) \(String(year)) · \(groupName)")
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
                            (unpaid.isEmpty ? AppTheme.success : AppTheme.coral),
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
                    ForEach(Array(unpaid.enumerated()), id: \.offset) { idx, player in
                        UnpaidPlayerRow(
                            player: player,
                            onMarkPaid: { onMarkPaid(player) }
                        )
                        if idx < unpaid.count - 1 {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    (unpaid.isEmpty ? AppTheme.success : AppTheme.coral).opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

struct UnpaidPlayerRow: View {
    let player: Player
    let onMarkPaid: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 34)

            Text(player.fullName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(.label))

            Spacer()

            Button(action: onMarkPaid) {
                Text("Mark Paid")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.success, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
