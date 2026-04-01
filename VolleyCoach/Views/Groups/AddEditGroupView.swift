import SwiftUI
import SwiftData

struct AddEditGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let coach: Coach
    var group: TeamGroup?

    @State private var name = ""
    @State private var ageCategory = ""
    @State private var colorHex = "#FF6B35"
    @State private var icon = "sportscourt.fill"
    @State private var selectedDays: Set<Int> = []
    @State private var trainingTime = Date()
    @State private var hasTime = false

    private var isEditing: Bool { group != nil }

    private let colors = [
        "#FF6B35", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#32ADE6", "#007AFF",
        "#5856D6", "#AF52DE", "#FF2D55", "#A2845E"
    ]

    private let icons = [
        "sportscourt.fill", "figure.volleyball", "trophy.fill",
        "star.fill", "bolt.fill", "flame.fill",
        "crown.fill", "shield.fill", "heart.fill",
        "flag.fill", "rosette", "medal.fill"
    ]

    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
    private let dayFull  = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Info") {
                    TextField("Name  (e.g. U16 Girls)", text: $name)
                    TextField("Age category (optional)", text: $ageCategory)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(height: 36)
                                .overlay {
                                    if hex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    colorHex = hex
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(icons, id: \.self) { sym in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(sym == icon ? Color(hex: colorHex) : Color.secondary.opacity(0.15))
                                    .frame(height: 40)
                                Image(systemName: sym)
                                    .font(.body)
                                    .foregroundStyle(sym == icon ? .white : .secondary)
                            }
                            .onTapGesture {
                                icon = sym
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Training Schedule") {
                    HStack(spacing: 6) {
                        ForEach(0..<7) { d in
                            let selected = selectedDays.contains(d)
                            Text(dayNames[d])
                                .font(.caption.bold())
                                .frame(width: 34, height: 34)
                                .background(selected ? Color(hex: colorHex) : Color.secondary.opacity(0.15), in: .circle)
                                .foregroundStyle(selected ? .white : .secondary)
                                .onTapGesture {
                                    if selected { selectedDays.remove(d) } else { selectedDays.insert(d) }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        }
                    }

                    Toggle("Training time", isOn: $hasTime.animation())

                    if hasTime {
                        DatePicker("Time", selection: $trainingTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        guard let g = group else { return }
        name        = g.name
        ageCategory = g.ageCategory
        colorHex    = g.colorHex
        icon        = g.icon
        selectedDays = Set(g.trainingDays)
        hasTime      = g.trainingTime != nil
        trainingTime = g.trainingTime ?? Date()
    }

    private func save() {
        if let g = group {
            g.name         = name.trimmed
            g.ageCategory  = ageCategory.trimmed
            g.colorHex     = colorHex
            g.icon         = icon
            g.trainingDays = Array(selectedDays).sorted()
            g.trainingTime = hasTime ? trainingTime : nil
        } else {
            let g = TeamGroup(name: name.trimmed, ageCategory: ageCategory.trimmed,
                              colorHex: colorHex, icon: icon)
            g.trainingDays = Array(selectedDays).sorted()
            g.trainingTime = hasTime ? trainingTime : nil
            modelContext.insert(g)
            coach.groups.append(g)
        }
        dismiss()
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}
