import SwiftUI
import SwiftData

struct CalendarTabView: View {
    let coach: Coach

    @Query private var allSessions: [TrainingSession]

    @State private var selectedDate = Date()
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var showingAdd = false
    @State private var recurringGroupToCreate: TeamGroup?

    private var coachGroupIDs: Set<PersistentIdentifier> {
        Set(coach.groups.map(\.persistentModelID))
    }

    private var trainingsForSelectedDate: [TrainingSession] {
        allSessions
            .filter { s in
                guard let g = s.group else { return false }
                return coachGroupIDs.contains(g.persistentModelID) &&
                       Calendar.current.isDate(s.date, inSameDayAs: selectedDate)
            }
            .sorted { $0.startTime < $1.startTime }
    }

    private var markedDays: Set<Date> {
        var days = Set(allSessions.compactMap { s -> Date? in
            guard let g = s.group, coachGroupIDs.contains(g.persistentModelID) else { return nil }
            return Calendar.current.startOfDay(for: s.date)
        })

        let calendar = Calendar.current
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        if let range = calendar.range(of: .day, in: .month, for: monthStart) {
            for day in range {
                guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
                let scheduleDay = calendar.component(.weekday, from: date) - 1
                if coach.groups.contains(where: { $0.trainingDays.contains(scheduleDay) }) {
                    days.insert(calendar.startOfDay(for: date))
                }
            }
        }
        return days
    }

    private var recurringGroupsForSelectedDate: [TeamGroup] {
        let scheduleDay = Calendar.current.component(.weekday, from: selectedDate) - 1
        let groupsWithRealSessions = Set(
            trainingsForSelectedDate.compactMap { $0.group?.persistentModelID }
        )
        return coach.groups
            .filter {
                $0.trainingDays.contains(scheduleDay) &&
                !groupsWithRealSessions.contains($0.persistentModelID)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Context row
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.footnote.weight(.bold))
                            Text("Plan the week")
                                .font(.footnote.weight(.bold))
                                .tracking(0.5)
                        }
                        .foregroundStyle(AppTheme.deepBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        // Month calendar
                        MonthCalendarView(
                            selectedDate: $selectedDate,
                            displayedMonth: $displayedMonth,
                            markedDays: markedDays
                        )

                        // Selected day trainings
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedDate, style: .date)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color(.label))
                                .padding(.horizontal)

                            if trainingsForSelectedDate.isEmpty && recurringGroupsForSelectedDate.isEmpty {
                                VStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.ocean)
                                    Text("No trainings scheduled")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(.regularMaterial,
                                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(AppTheme.softGradient.opacity(0.4), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(trainingsForSelectedDate) { session in
                                        NavigationLink(destination: TrainingAttendanceView(session: session)) {
                                            TrainingCard(session: session)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    ForEach(recurringGroupsForSelectedDate) { group in
                                        Button {
                                            recurringGroupToCreate = group
                                        } label: {
                                            ScheduledTrainingCard(group: group)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityHint("Creates a training session from this weekly schedule")
                                    }
                                }
                            }

                            Button { showingAdd = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Training")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .shadow(color: AppTheme.deepBlue.opacity(0.26),
                                        radius: 14, x: 0, y: 8)
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Schedule")
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAdd) {
                AddTrainingView(groups: coach.groups, prefilledDate: selectedDate)
            }
            .sheet(item: $recurringGroupToCreate) { group in
                AddTrainingView(
                    groups: [group],
                    preselectedGroup: group,
                    prefilledDate: selectedDate
                )
            }
        }
    }
}

// MARK: - MonthCalendarView

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    let markedDays: Set<Date>

    private let calendar = Calendar.current
    private let weekdayHeaders = ["Mo","Tu","We","Th","Fr","Sa","Su"]

    // Monday-first day cells (nil = empty padding cell)
    private var cells: [Date?] {
        let start = calendar.startOfMonth(for: displayedMonth)
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }

        // weekday: 1=Sun,2=Mon,...,7=Sat → Monday-first offset: (weekday + 5) % 7
        let weekday = calendar.component(.weekday, from: start)
        let offset = (weekday + 5) % 7

        var result: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                result.append(date)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title3)
                }
                .heroGradientForeground()

                Spacer()

                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color(.label))

                Spacer()

                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                }
                .heroGradientForeground()
            }
            .padding(.horizontal)

            // Day-of-week headers
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.self) { d in
                    Text(d)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)

            // Day grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 4
            ) {
                ForEach(0..<cells.count, id: \.self) { i in
                    if let date = cells[i] {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasTraining: markedDays.contains(calendar.startOfDay(for: date))
                        )
                        .onTapGesture {
                            selectedDate = date
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } else {
                        Color.clear.frame(height: 52)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.12),
                radius: 24, x: 0, y: 12)
        .padding(.horizontal)
    }

    private func changeMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = next
        }
    }
}

// MARK: - CalendarDayCell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTraining: Bool

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(AppTheme.heroGradient)
                        .shadow(color: AppTheme.deepBlue.opacity(0.38),
                                radius: 10, x: 0, y: 6)
                } else if isToday {
                    Circle()
                        .strokeBorder(AppTheme.heroGradient, lineWidth: 2)
                }
                Text(dayNumber)
                    .font(.callout)
                    .fontWeight(isSelected || isToday ? .bold : .regular)
                    .foregroundStyle(
                        isSelected ? AnyShapeStyle(Color.white)
                                   : AnyShapeStyle(Color(.label))
                    )
            }
            .frame(width: 38, height: 38)

            Circle()
                .fill(
                    hasTraining
                        ? (isSelected ? AnyShapeStyle(Color.white.opacity(0.9))
                                      : AnyShapeStyle(AppTheme.heroGradient))
                        : AnyShapeStyle(Color.clear)
                )
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }
}

// MARK: - TrainingCard

struct TrainingCard: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.heroGradient.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "figure.volleyball")
                    .font(.title3.weight(.semibold))
                    .heroGradientForeground()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.group?.name ?? "Group")
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                Text(session.timeRange)
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            if session.attendanceTaken {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.softGradient.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.09),
                radius: 14, x: 0, y: 6)
        .padding(.horizontal)
    }
}

struct ScheduledTrainingCard: View {
    let group: TeamGroup

    private var timeText: String {
        guard let time = group.trainingTime else { return "Time not set" }
        return time.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.energyGradient.opacity(0.28))
                    .frame(width: 48, height: 48)
                Image(systemName: "repeat")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.deepBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Weekly schedule · \(timeText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("SCHEDULED")
                .font(.system(size: 9, weight: .black))
                .tracking(0.7)
                .foregroundStyle(AppTheme.deepBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AppTheme.sun.opacity(0.30), in: Capsule())

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.ocean)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.sun.opacity(0.40), lineWidth: 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.08), radius: 12, y: 6)
        .padding(.horizontal)
    }
}
