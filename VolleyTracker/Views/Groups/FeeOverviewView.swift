import SwiftUI
import SwiftData

struct FeeOverviewView: View {
    let group: TeamGroup
    @Environment(\.modelContext) private var modelContext

    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var unpaidOnly = false

    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    private var visiblePlayers: [Player] {
        let sorted = group.players.sorted { $0.fullName < $1.fullName }
        guard unpaidOnly else { return sorted }
        return sorted.filter { player in
            let rec = player.feeRecords.first { $0.month == currentMonth && $0.year == year }
            return rec?.status != .paid
        }
    }

    private var paidCount: Int {
        group.players.filter { player in
            player.feeRecords.first { $0.month == currentMonth && $0.year == year }?.status == .paid
        }.count
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
