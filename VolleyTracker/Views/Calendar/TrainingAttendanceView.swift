import SwiftUI
import SwiftData

private enum AttendanceFilter: String, CaseIterable {
    case all = "All"
    case unmarked = "Unmarked"
    case present = "Present"
    case absent = "Absent"
    case late = "Late"
    case excused = "Excused"

    var status: AttendanceStatus? {
        switch self {
        case .all, .unmarked: nil
        case .present: .present
        case .absent: .absent
        case .late: .late
        case .excused: .excused
        }
    }
}

struct TrainingAttendanceView: View {
    let session: TrainingSession
    @Environment(\.modelContext) private var modelContext

    @State private var statusMap: [PersistentIdentifier: AttendanceStatus] = [:]
    @State private var searchText = ""
    @State private var filter: AttendanceFilter = .all
    @State private var isDirty = false
    @State private var showSaved = false
    @State private var undoSnapshot: [PersistentIdentifier: AttendanceStatus]?
    @State private var showUndo = false
    @State private var undoTask: Task<Void, Never>?

    private var group: TeamGroup? { session.group }
    private var teamTint: Color { Color(teamHex: group?.colorHex ?? "") }

    private var players: [Player] {
        group?.players.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending } ?? []
    }

    private var searchedPlayers: [Player] {
        guard !searchText.trimmed.isEmpty else { return players }
        return players.filter { player in
            player.fullName.localizedCaseInsensitiveContains(searchText) ||
            player.jerseyNumber.map { "\($0)".contains(searchText) } == true
        }
    }

    private var visiblePlayers: [Player] {
        searchedPlayers.filter { player in
            let status = statusMap[player.persistentModelID]
            switch filter {
            case .all:
                return true
            case .unmarked:
                return status == nil
            default:
                return status == filter.status
            }
        }
    }

    private var unmarkedCount: Int {
        players.filter { statusMap[$0.persistentModelID] == nil }.count
    }

    private var navTitle: String {
        session.group?.name ?? "Attendance"
    }

    var body: some View {
        ZStack {
            CourtWorkspaceBackground()

            if players.isEmpty {
                emptyRosterState
            } else {
                List {
                    Section {
                        attendanceHeader
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        ForEach(visiblePlayers) { player in
                            AttendancePlayerRow(
                                player: player,
                                teamTint: teamTint,
                                status: Binding(
                                    get: { statusMap[player.persistentModelID] },
                                    set: { newValue in
                                        statusMap[player.persistentModelID] = newValue
                                        isDirty = true
                                    }
                                )
                            )
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    setStatus(.present, for: player)
                                } label: {
                                    Label("Present", systemImage: "checkmark.circle.fill")
                                }
                                .tint(AppTheme.success)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    setStatus(.absent, for: player)
                                } label: {
                                    Label("Absent", systemImage: "xmark.circle.fill")
                                }
                                .tint(AppTheme.coral)
                            }
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text(LocalizedStringKey(sectionTitle))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { markAll(.present) } label: {
                        Label("Mark All Present", systemImage: "checkmark.circle.fill")
                    }
                    Button { markAll(.absent) } label: {
                        Label("Mark All Absent", systemImage: "xmark.circle.fill")
                    }
                    Button { clearAll() } label: {
                        Label("Clear Marks", systemImage: "eraser")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .heroGradientForeground()
                }
                .disabled(players.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !players.isEmpty {
                bottomSaveBar
            }
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .onAppear(perform: load)
        .onDisappear { undoTask?.cancel() }
    }

    private var attendanceHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                CourtIconBadge(icon: "figure.volleyball", tint: teamTint, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.headline)
                    Text(session.timeRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Roster progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(players.count - unmarkedCount)/\(players.count)")
                        .font(.caption.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(teamTint)
                        .contentTransition(.numericText())
                }
                ProgressView(
                    value: Double(players.count - unmarkedCount),
                    total: Double(max(players.count, 1))
                )
                .tint(teamTint)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: unmarkedCount)
            }

            HStack(spacing: 8) {
                summaryCell("Present", count: count(.present), color: AppTheme.success)
                summaryCell("Absent", count: count(.absent), color: AppTheme.coral)
                summaryCell("Late", count: count(.late), color: AppTheme.sun)
                summaryCell("Unmarked", count: unmarkedCount, color: .secondary)
            }

            AttendanceSearchField(text: $searchText)

            Picker("Attendance Filter", selection: $filter) {
                ForEach(AttendanceFilter.allCases, id: \.self) { item in
                    Text(LocalizedStringKey(item.rawValue)).tag(item)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Button { markAll(.present) } label: {
                    Label("All Present", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(CourtSecondaryButtonStyle())

                Button { clearAll() } label: {
                    Label("Clear", systemImage: "eraser")
                }
                .buttonStyle(CourtSecondaryButtonStyle())
            }

            Label(
                "Swipe right for present · left for absent",
                systemImage: "hand.draw.fill"
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AppTheme.ocean.opacity(0.16), lineWidth: 1))
    }

    private var sectionTitle: String {
        if searchText.trimmed.isEmpty {
            return "\(visiblePlayers.count) players"
        }
        return "\(visiblePlayers.count) matching players"
    }

    private var bottomSaveBar: some View {
        VStack(spacing: 8) {
            Button(action: save) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(isDirty || !session.attendanceTaken ? "Save Attendance" : "Saved")
                }
            }
            .buttonStyle(CourtPrimaryButtonStyle())
            .disabled(!isDirty && session.attendanceTaken)

            if unmarkedCount > 0 {
                Text("Unmarked players will be saved as absent.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }

    private var emptyRosterState: some View {
        VStack(spacing: 18) {
            CourtIconBadge(icon: "person.badge.plus", tint: AppTheme.ocean, size: 74)
            VStack(spacing: 6) {
                Text("No players to mark")
                    .font(.title3.weight(.bold))
                Text("Add players to this team before taking attendance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: 350)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AppTheme.ocean.opacity(0.15), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 22)
    }

    private func summaryCell(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(LocalizedStringKey(label))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func count(_ status: AttendanceStatus) -> Int {
        statusMap.values.filter { $0 == status }.count
    }

    private func load() {
        statusMap = [:]
        for record in session.attendanceRecords {
            if let playerID = record.player?.persistentModelID {
                statusMap[playerID] = record.status
            }
        }
        isDirty = !session.attendanceTaken
    }

    private func markAll(_ status: AttendanceStatus) {
        prepareUndo()
        for player in players {
            statusMap[player.persistentModelID] = status
        }
        isDirty = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func clearAll() {
        prepareUndo()
        statusMap = [:]
        isDirty = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func save() {
        for record in session.attendanceRecords {
            modelContext.delete(record)
        }
        session.attendanceRecords = []

        for player in players {
            let status = statusMap[player.persistentModelID] ?? .absent
            let record = AttendanceRecord(player: player, status: status)
            modelContext.insert(record)
            session.attendanceRecords.append(record)
        }

        Task { try? await CloudDataService.shared.replaceAttendance(for: session) }
        isDirty = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeOut(duration: 0.2)) { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) { showSaved = false }
        }
    }

    private func setStatus(_ status: AttendanceStatus, for player: Player) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
            statusMap[player.persistentModelID] = status
            isDirty = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func prepareUndo() {
        undoTask?.cancel()
        undoSnapshot = statusMap
        withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
            showUndo = true
        }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    showUndo = false
                }
                undoSnapshot = nil
            }
        }
    }

    private func undoBulkChange() {
        guard let undoSnapshot else { return }
        undoTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            statusMap = undoSnapshot
            isDirty = true
            showUndo = false
        }
        self.undoSnapshot = nil
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    @ViewBuilder
    private var toastOverlay: some View {
        VStack(spacing: 8) {
            if showSaved {
                HStack(spacing: 8) {
                    Image(systemName: "figure.volleyball")
                        .symbolEffect(.bounce, value: showSaved)
                    Text("Attendance saved")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.success, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showUndo {
                HStack(spacing: 12) {
                    Text("Roster updated")
                        .font(.subheadline.weight(.semibold))
                    Button("Undo", action: undoBulkChange)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.sun)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color.black.opacity(0.82), in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 84)
    }
}

private struct AttendanceSearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isFocused ? AppTheme.ocean : .secondary)
            TextField("Search player or jersey", text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(isFocused ? AppTheme.ocean.opacity(0.45) : AppTheme.ocean.opacity(0.16), lineWidth: 1))
    }
}

struct AttendancePlayerRow: View {
    let player: Player
    let teamTint: Color
    @Binding var status: AttendanceStatus?

    private var resolvedStatus: AttendanceStatus? { status }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PlayerAvatarView(photoData: player.photoData, name: player.fullName, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        if let number = player.jerseyNumber {
                            Text("#\(number)")
                        }
                        if player.position != .unknown {
                            Text(LocalizedStringKey(player.position.rawValue))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                statusChip
            }

            HStack(spacing: 8) {
                statusButton(.present)
                statusButton(.absent)
                statusButton(.late)
                statusButton(.excused)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder((resolvedStatus?.color ?? teamTint).opacity(0.22), lineWidth: 1))
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: status)
    }

    private var statusChip: some View {
        Group {
            if let resolvedStatus {
                Label(LocalizedStringKey(resolvedStatus.rawValue), systemImage: resolvedStatus.sfSymbol)
                    .foregroundStyle(resolvedStatus.color)
                    .background(resolvedStatus.color.opacity(0.12), in: Capsule())
            } else {
                Label("Unmarked", systemImage: "circle")
                    .foregroundStyle(.secondary)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private func statusButton(_ target: AttendanceStatus) -> some View {
        Button {
            status = status == target ? nil : target
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: target.sfSymbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(status == target ? .white : target.color)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(status == target ? target.color : target.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .scaleEffect(status == target ? 1 : 0.96)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(target.rawValue)
    }
}
