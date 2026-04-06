import SwiftUI
import SwiftData

struct CalendarTabView: View {
    let coach: Coach

    @Query private var allSessions: [TrainingSession]

    @State private var selectedDate = Date()
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var showingAdd = false

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
        Set(allSessions.compactMap { s -> Date? in
            guard let g = s.group, coachGroupIDs.contains(g.persistentModelID) else { return nil }
            return Calendar.current.startOfDay(for: s.date)
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month calendar
                    MonthCalendarView(
                        selectedDate: $selectedDate,
                        displayedMonth: $displayedMonth,
                        markedDays: markedDays
                    )

                    // Selected day trainings
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedDate, style: .date)
                            .font(.headline)
                            .foregroundStyle(Color(.label))
                            .padding(.horizontal)

                        if trainingsForSelectedDate.isEmpty {
                            Text("No trainings scheduled.")
                                .font(.subheadline)
                                .foregroundStyle(Color(.secondaryLabel))
                                .padding(.horizontal)
                        } else {
                            ForEach(trainingsForSelectedDate) { session in
                                NavigationLink(destination: TrainingAttendanceView(session: session)) {
                                    TrainingCard(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button { showingAdd = true } label: {
                            Label("Add Training", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(AppTheme.activeBlue)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .background(AppTheme.skyBlue)
            .navigationTitle("Calendar")
            .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAdd) {
                AddTrainingView(groups: coach.groups, prefilledDate: selectedDate)
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
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(AppTheme.activeBlue)

                Spacer()

                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                Spacer()

                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(AppTheme.activeBlue)
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
        .padding(.vertical, 12)
        .background(AppTheme.cardSurface, in: .rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
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
        VStack(spacing: 2) {
            Text(dayNumber)
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .frame(width: 36, height: 36)
                .background(isSelected ? AppTheme.activeBlue : Color.clear, in: .circle)
                .foregroundStyle(
                    isSelected ? .white :
                    isToday    ? AppTheme.activeBlue :
                    Color(.label)
                )

            Circle()
                .fill(hasTraining ? (isSelected ? Color.white.opacity(0.8) : AppTheme.activeBlue) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
    }
}

// MARK: - TrainingCard

struct TrainingCard: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.volleyball")
                .font(.title3)
                .foregroundStyle(AppTheme.courtBlueLite)
                .frame(width: 44, height: 44)
                .background(AppTheme.activeBlue.opacity(0.1), in: .rect(cornerRadius: 10))

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
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.successGreen)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding()
        .background(AppTheme.cardSurface, in: .rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
