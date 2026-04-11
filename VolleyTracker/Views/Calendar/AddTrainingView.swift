import SwiftUI
import SwiftData

struct AddTrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let groups: [TeamGroup]

    @State private var selectedGroup: TeamGroup?
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes = ""

    // Called with [group] + same group when launched from AttendanceView
    // Called with coach.groups + nil when launched from CalendarTabView
    init(groups: [TeamGroup], preselectedGroup: TeamGroup? = nil, prefilledDate: Date = Date()) {
        self.groups = groups
        _selectedGroup = State(initialValue: preselectedGroup ?? groups.first)
        _date = State(initialValue: prefilledDate)

        // Default: 17:00 – 18:30 on prefilledDate
        var start = Calendar.current.dateComponents([.year, .month, .day], from: prefilledDate)
        start.hour = 17; start.minute = 0
        let startDate = Calendar.current.date(from: start) ?? prefilledDate

        var end = Calendar.current.dateComponents([.year, .month, .day], from: prefilledDate)
        end.hour = 18; end.minute = 30
        let endDate = Calendar.current.date(from: end) ?? prefilledDate

        _startTime = State(initialValue: startDate)
        _endTime   = State(initialValue: endDate)
    }

    private var canSave: Bool { selectedGroup != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        // Sparkle eyebrow
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.footnote.weight(.bold))
                            Text("New training session")
                                .font(.footnote.weight(.bold))
                                .tracking(0.5)
                        }
                        .heroGradientForeground()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        // Group section
                        VStack(alignment: .leading, spacing: 10) {
                            ThemedSectionLabel("GROUP")
                                .padding(.horizontal, 20)

                            glassCard {
                                if groups.count > 1 {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(AppTheme.heroGradient.opacity(0.18))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "person.3.fill")
                                                .font(.footnote.weight(.bold))
                                                .heroGradientForeground()
                                        }
                                        Text("Group")
                                            .font(.body)
                                            .foregroundStyle(Color(.label))
                                        Spacer()
                                        Picker("Group", selection: $selectedGroup) {
                                            Text("Select").tag(Optional<TeamGroup>.none)
                                            ForEach(groups) { g in
                                                Text(g.name).tag(Optional(g))
                                            }
                                        }
                                        .labelsHidden()
                                        .tint(Color(red: 0.24, green: 0.40, blue: 1.00))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                } else if let g = selectedGroup {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(AppTheme.heroGradient.opacity(0.18))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "person.3.fill")
                                                .font(.footnote.weight(.bold))
                                                .heroGradientForeground()
                                        }
                                        Text("Group")
                                            .font(.body)
                                            .foregroundStyle(Color(.label))
                                        Spacer()
                                        Text(g.name)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(Color(.secondaryLabel))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Schedule section
                        VStack(alignment: .leading, spacing: 10) {
                            ThemedSectionLabel("SCHEDULE")
                                .padding(.horizontal, 20)

                            glassCard {
                                VStack(spacing: 0) {
                                    ThemedDatePickerRow(icon: "calendar",
                                                        label: "Date",
                                                        selection: $date,
                                                        components: .date)
                                    Divider().padding(.leading, 54)
                                    ThemedDatePickerRow(icon: "clock.fill",
                                                        label: "Start Time",
                                                        selection: $startTime,
                                                        components: .hourAndMinute)
                                    Divider().padding(.leading, 54)
                                    ThemedDatePickerRow(icon: "clock.badge.checkmark.fill",
                                                        label: "End Time",
                                                        selection: $endTime,
                                                        components: .hourAndMinute)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Notes section
                        VStack(alignment: .leading, spacing: 10) {
                            ThemedSectionLabel("NOTES")
                                .padding(.horizontal, 20)

                            glassCard {
                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(AppTheme.heroGradient.opacity(0.18))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "note.text")
                                            .font(.footnote.weight(.bold))
                                            .heroGradientForeground()
                                    }
                                    .padding(.top, 2)

                                    TextField("Optional notes", text: $notes, axis: .vertical)
                                        .font(.body)
                                        .foregroundStyle(Color(.label))
                                        .lineLimit(3...6)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Add Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(.secondaryLabel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        Text("Save")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(AppTheme.heroGradient, in: Capsule())
                            .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.35),
                                    radius: 10, x: 0, y: 5)
                            .opacity(canSave ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
            }
        }
    }

    @ViewBuilder
    private func glassCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.10),
                    radius: 18, x: 0, y: 10)
    }

    private func save() {
        guard let group = selectedGroup else { return }

        let session = TrainingSession(
            date: date,
            startTime: startTime,
            endTime: endTime,
            notes: notes.trimmed
        )
        modelContext.insert(session)
        group.trainingSessions.append(session)

        dismiss()
    }
}

// MARK: - Themed date picker row

private struct ThemedDatePickerRow: View {
    let icon: String
    let label: String
    @Binding var selection: Date
    let components: DatePickerComponents

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.heroGradient.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .heroGradientForeground()
            }
            Text(label)
                .font(.body)
                .foregroundStyle(Color(.label))
            Spacer()
            DatePicker("", selection: $selection, displayedComponents: components)
                .labelsHidden()
                .tint(Color(red: 0.24, green: 0.40, blue: 1.00))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
