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
            Form {
                if groups.count > 1 {
                    Section("Group") {
                        Picker("Group", selection: $selectedGroup) {
                            Text("Select a group").tag(Optional<TeamGroup>.none)
                            ForEach(groups) { g in
                                Text(g.name).tag(Optional(g))
                            }
                        }
                    }
                } else if let g = selectedGroup {
                    Section {
                        LabeledContent("Group", value: g.name)
                    }
                }

                Section("Schedule") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
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
