import SwiftData
import SwiftUI

struct DashboardHomeView: View {
    let coach: Coach

    @State private var showingAddGroup = false
    @State private var showingAddTraining = false
    @State private var addPlayerGroup: TeamGroup?
    @State private var feeGroup: TeamGroup?
    @State private var hasAppeared = false

    private var groups: [TeamGroup] {
        coach.groups.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var players: [Player] {
        groups.flatMap(\.players)
    }

    private var sessions: [TrainingSession] {
        groups.flatMap(\.trainingSessions)
    }

    private var nextSession: TrainingSession? {
        let now = Date()
        return sessions
            .filter { $0.scheduledEnd >= now }
            .sorted { $0.scheduledStart < $1.scheduledStart }
            .first
    }

    private var todaySessions: [TrainingSession] {
        sessions
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.scheduledStart < $1.scheduledStart }
    }

    private var upcomingSessions: [TrainingSession] {
        let now = Date()
        return sessions
            .filter {
                $0.scheduledStart >= now && !Calendar.current.isDateInToday($0.date)
            }
            .sorted { $0.scheduledStart < $1.scheduledStart }
            .prefix(4)
            .map { $0 }
    }

    private var unpaidPlayers: [Player] {
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        return players
            .filter { player in
                player.feeRecords.first {
                    $0.month == month && $0.year == year
                }?.status != .paid
            }
            .sorted { $0.fullName < $1.fullName }
    }

    private var attendanceRate: Double {
        let records = sessions
            .filter(\.attendanceTaken)
            .flatMap(\.attendanceRecords)
        guard !records.isEmpty else { return 0 }
        let present = records.filter { $0.status == .present }.count
        return Double(present) / Double(records.count) * 100
    }

    private var upcomingBirthdayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let limit = calendar.date(byAdding: .day, value: 14, to: today) else { return 0 }

        return players.filter { player in
            guard let birthDate = player.dateOfBirth else { return false }
            let birthParts = calendar.dateComponents([.month, .day], from: birthDate)
            let year = calendar.component(.year, from: today)
            var nextParts = DateComponents(
                year: year,
                month: birthParts.month,
                day: birthParts.day
            )
            var nextBirthday = calendar.date(from: nextParts) ?? birthDate
            if nextBirthday < today {
                nextParts.year = year + 1
                nextBirthday = calendar.date(from: nextParts) ?? nextBirthday
            }
            return nextBirthday <= limit
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CourtWorkspaceBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                            .dashboardEntrance(hasAppeared, delay: 0)
                        nextTrainingHero
                            .dashboardEntrance(hasAppeared, delay: 0.05)
                        quickActions
                            .dashboardEntrance(hasAppeared, delay: 0.10)
                        teamPulse
                            .dashboardEntrance(hasAppeared, delay: 0.15)
                        todaySection
                            .dashboardEntrance(hasAppeared, delay: 0.20)
                        upcomingSection
                            .dashboardEntrance(hasAppeared, delay: 0.25)
                        unpaidSection
                            .dashboardEntrance(hasAppeared, delay: 0.30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(Text("Dashboard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showingAddTraining = true } label: {
                            Label("Add Training", systemImage: "calendar.badge.plus")
                        }
                        Button { showingAddGroup = true } label: {
                            Label("Add Team", systemImage: "person.3.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .heroGradientForeground()
                    }
                    .accessibilityLabel("Add")
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddEditGroupView(coach: coach)
            }
            .sheet(isPresented: $showingAddTraining) {
                AddTrainingView(groups: coach.groups)
            }
            .sheet(item: $addPlayerGroup) { group in
                AddEditPlayerView(group: group)
            }
            .sheet(item: $feeGroup) { group in
                DashboardFeeSheet(group: group)
            }
            .task {
                guard !hasAppeared else { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                    hasAppeared = true
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                (
                    Text(LocalizedStringKey(Greeting.forNow()))
                    + Text(", ")
                    + Text("Coach")
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ocean)

                Text(coach.club.isEmpty ? coach.name : coach.club)
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PlayerAvatarView(photoData: coach.photoData, name: coach.name, size: 48)
                .overlay(Circle().strokeBorder(AppTheme.softGradient, lineWidth: 2))
                .shadow(color: AppTheme.shadow, radius: 10, y: 5)
        }
    }

    @ViewBuilder
    private var nextTrainingHero: some View {
        if let session = nextSession {
            NavigationLink(destination: TrainingAttendanceView(session: session)) {
                NextTrainingCard(session: session)
            }
            .buttonStyle(.plain)
        } else {
            Button { showingAddTraining = true } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        CourtIconBadge(
                            icon: "calendar.badge.plus",
                            tint: AppTheme.sun,
                            size: 48
                        )
                        Spacer()
                        Text("READY FOR THE NEXT SERVE")
                            .font(.caption2.weight(.black))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    Text("Plan your next training")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Label("Add Training", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.sun)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.deepGradient, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppTheme.deepBlue.opacity(0.28), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            CourtSectionLabel("QUICK ACTIONS", subtitle: "The essentials, one tap away.")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                Button { showingAddTraining = true } label: {
                    DashboardActionLabel(
                        title: "New Training",
                        icon: "calendar.badge.plus",
                        tint: AppTheme.ocean,
                        featured: true
                    )
                }
                .buttonStyle(.plain)

                Button { showingAddGroup = true } label: {
                    DashboardActionLabel(
                        title: "Add Team",
                        icon: "person.3.fill",
                        tint: AppTheme.deepBlue
                    )
                }
                .buttonStyle(.plain)

                Menu {
                    if groups.isEmpty {
                        Button("Create a team first") { showingAddGroup = true }
                    } else {
                        ForEach(groups) { group in
                            Button(group.name) { addPlayerGroup = group }
                        }
                    }
                } label: {
                    DashboardActionLabel(
                        title: "Add Player",
                        icon: "person.badge.plus",
                        tint: AppTheme.cyan
                    )
                }

                Menu {
                    if groups.isEmpty {
                        Button("Create a team first") { showingAddGroup = true }
                    } else {
                        ForEach(groups) { group in
                            Button(group.name) { feeGroup = group }
                        }
                    }
                } label: {
                    DashboardActionLabel(
                        title: "Record Payment",
                        icon: "banknote.fill",
                        tint: AppTheme.success
                    )
                }
            }
        }
    }

    private var teamPulse: some View {
        VStack(alignment: .leading, spacing: 10) {
            CourtSectionLabel("TEAM PULSE", subtitle: "What needs your attention right now.")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                PulseCell(
                    value: "\(nextSession?.group?.players.count ?? players.count)",
                    label: "Expected next",
                    icon: "person.3.fill",
                    tint: nextSession.map { Color(teamHex: $0.group?.colorHex ?? "") }
                        ?? AppTheme.ocean
                )
                PulseCell(
                    value: "\(unpaidPlayers.count)",
                    label: "Unpaid fees",
                    icon: "banknote.fill",
                    tint: unpaidPlayers.isEmpty ? AppTheme.success : AppTheme.coral
                )
                PulseCell(
                    value: String(format: "%.0f%%", attendanceRate),
                    label: "Attendance",
                    icon: "checkmark.seal.fill",
                    tint: attendanceRate >= 80 ? AppTheme.success : AppTheme.sun
                )
                PulseCell(
                    value: "\(upcomingBirthdayCount)",
                    label: "Birthdays soon",
                    icon: "birthday.cake.fill",
                    tint: AppTheme.cyan
                )
            }
        }
    }

    private var todaySection: some View {
        DashboardSection(
            title: "Today",
            subtitle: todaySessions.isEmpty
                ? "No sessions scheduled"
                : "Tap a session to mark attendance"
        ) {
            if todaySessions.isEmpty {
                DashboardEmptyRow(
                    icon: "calendar.badge.plus",
                    title: "Add today’s first training",
                    tint: AppTheme.ocean
                ) {
                    showingAddTraining = true
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(todaySessions) { session in
                        NavigationLink(destination: TrainingAttendanceView(session: session)) {
                            DashboardSessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var upcomingSection: some View {
        DashboardSection(
            title: "Upcoming",
            subtitle: upcomingSessions.isEmpty
                ? "Your next trainings will appear here"
                : nil
        ) {
            if upcomingSessions.isEmpty {
                DashboardEmptyRow(
                    icon: "calendar",
                    title: "Plan the schedule",
                    tint: AppTheme.deepBlue
                ) {
                    showingAddTraining = true
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(upcomingSessions) { session in
                        NavigationLink(destination: TrainingAttendanceView(session: session)) {
                            DashboardSessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var unpaidSection: some View {
        DashboardSection(
            title: "Fees",
            subtitle: unpaidPlayers.isEmpty
                ? "All current fees are paid"
                : "\(unpaidPlayers.count) unpaid this month"
        ) {
            if unpaidPlayers.isEmpty {
                HStack(spacing: 12) {
                    CourtIconBadge(
                        icon: "checkmark.seal.fill",
                        tint: AppTheme.success,
                        size: 42
                    )
                    Text("No unpaid fees for this month")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(14)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(unpaidPlayers.prefix(4)) { player in
                        HStack(spacing: 12) {
                            PlayerAvatarView(
                                photoData: player.photoData,
                                name: player.fullName,
                                size: 34
                            )
                            Text(player.fullName)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("Unpaid")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.coral)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AppTheme.coral.opacity(0.12), in: Capsule())
                        }
                        .padding(12)
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                }
            }
        }
    }
}

private struct NextTrainingCard: View {
    let session: TrainingSession

    private var tint: Color {
        Color(teamHex: session.group?.colorHex ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("NEXT TRAINING")
                        .font(.caption2.weight(.black))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(session.group?.name ?? String(localized: "Training"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    HStack(spacing: 5) {
                        Image(systemName: "person.3.fill")
                        Text("\(session.group?.players.count ?? 0)")
                        Text("expected")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Text(session.group?.emoji ?? "🏐")
                    .font(.system(size: 34))
                    .padding(8)
                    .background(.white.opacity(0.14), in: Circle())
            }

            HStack(spacing: 16) {
                Label {
                    Text(session.scheduledStart, format: .dateTime.weekday(.abbreviated).day().month())
                } icon: {
                    Image(systemName: "calendar")
                }
                Label(session.timeRange, systemImage: "clock.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Starts")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                    Text(session.scheduledStart, style: .relative)
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.sun)
                }

                Spacer()

                Label("Take Attendance", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.deepBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white, in: Capsule())
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.94), AppTheme.deepBlue, AppTheme.ocean],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.30), radius: 20, y: 12)
    }
}

private struct DashboardActionLabel: View {
    let title: String
    let icon: String
    let tint: Color
    var featured = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 0)
        }
        .foregroundStyle(featured ? .white : tint)
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
            featured ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(tint.opacity(0.12)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    featured ? .white.opacity(0.16) : tint.opacity(0.22),
                    lineWidth: 1
                )
        )
        .shadow(color: featured ? tint.opacity(0.22) : .clear, radius: 10, y: 5)
    }
}

private struct PulseCell: View {
    let value: String
    let label: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 11) {
            CourtIconBadge(icon: icon, tint: tint, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(LocalizedStringKey(label))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct DashboardSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CourtSectionLabel(title, subtitle: subtitle)
            content()
        }
    }
}

private struct DashboardSessionRow: View {
    let session: TrainingSession

    private var tint: Color {
        Color(teamHex: session.group?.colorHex ?? "")
    }

    var body: some View {
        HStack(spacing: 12) {
            CourtIconBadge(
                icon: session.attendanceTaken
                    ? "checkmark.seal.fill"
                    : "figure.volleyball",
                tint: session.attendanceTaken ? AppTheme.success : tint,
                size: 42
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(session.group?.name ?? String(localized: "Training"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(session.scheduledStart, format: .dateTime.weekday(.abbreviated).day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.timeRange)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct DashboardEmptyRow: View {
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CourtIconBadge(icon: icon, tint: tint, size: 42)
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(tint)
            }
            .padding(14)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardFeeSheet: View {
    let group: TeamGroup
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FeeOverviewView(group: group)
                .navigationTitle(group.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

private extension View {
    func dashboardEntrance(_ visible: Bool, delay: Double) -> some View {
        opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.88).delay(delay),
                value: visible
            )
    }
}
