import SwiftUI
import SwiftData

struct AddEditGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let coach: Coach
    var group: TeamGroup?

    @State private var name = ""
    @State private var ageCategory = ""
    @State private var colorHex = "#007AFF"
    @State private var emoji = "🏐"
    @State private var selectedDays: Set<Int> = []
    @State private var trainingTime = Date()
    @State private var hasTime = false

    private var isEditing: Bool { group != nil }

    private let colors = [
        "#007AFF","#5AC8FA","#34C759","#30D158",
        "#FF9500","#FF3B30","#FF2D55","#AF52DE",
        "#5856D6","#00C7BE","#A2845E","#636366"
    ]

    private let dayLetters = ["S","M","T","W","T","F","S"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Info") {
                    TextField("Name (e.g. U16 Girls)", text: $name)
                    TextField("Age category (optional)", text: $ageCategory)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            colorSwatch(hex)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Group Icon") {
                    VStack(spacing: 12) {
                        TextField("", text: $emoji)
                            .font(.system(size: 60))
                            .multilineTextAlignment(.center)
                            .onChange(of: emoji) { _, newVal in
                                if let lastChar = newVal.last, lastChar.isEmoji {
                                    emoji = String(lastChar)
                                } else if newVal.isEmpty {
                                    emoji = "🏐"
                                } else {
                                    emoji = "🏐"
                                }
                            }

                        Text("Tap to choose an emoji")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Training Schedule") {
                    HStack(spacing: 4) {
                        ForEach(0..<7) { d in
                            dayButton(d)
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
                        .disabled(name.trimmed.isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    // MARK: Sub-views

    private func colorSwatch(_ hex: String) -> some View {
        let hexColor = hexToColor(hex)
        return Circle()
            .fill(hexColor)
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

    private func dayButton(_ d: Int) -> some View {
        let selected = selectedDays.contains(d)
        return Text(dayLetters[d])
            .font(.caption.bold())
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(selected ? hexToColor(colorHex) : Color(.secondarySystemGroupedBackground),
                        in: .circle)
            .foregroundStyle(selected ? .white : Color(.secondaryLabel))
            .onTapGesture {
                if selected { selectedDays.remove(d) } else { selectedDays.insert(d) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
    }

    // MARK: Helpers

    private func hexToColor(_ hex: String) -> Color {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        return Color(
            red:   Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >>  8) / 255,
            blue:  Double( rgb & 0x0000FF       ) / 255
        )
    }

    private func loadIfEditing() {
        guard let g = group else { return }
        name         = g.name
        ageCategory  = g.ageCategory
        colorHex     = g.colorHex
        emoji        = g.emoji
        selectedDays = Set(g.trainingDays)
        hasTime      = g.trainingTime != nil
        trainingTime = g.trainingTime ?? Date()
    }

    private func save() {
        if let g = group {
            g.name         = name.trimmed
            g.ageCategory  = ageCategory.trimmed
            g.colorHex     = colorHex
            g.emoji        = emoji
            g.trainingDays = Array(selectedDays).sorted()
            g.trainingTime = hasTime ? trainingTime : nil
        } else {
            let g = TeamGroup(
                name: name.trimmed,
                ageCategory: ageCategory.trimmed,
                colorHex: colorHex,
                emoji: emoji
            )
            g.trainingDays = Array(selectedDays).sorted()
            g.trainingTime = hasTime ? trainingTime : nil
            modelContext.insert(g)
            coach.groups.append(g)
        }
        dismiss()
    }
}
