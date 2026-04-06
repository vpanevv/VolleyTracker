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
    @State private var emoji = "👦"
    @State private var selectedDays: Set<Int> = []
    @State private var trainingTime = Date()
    @State private var hasTime = false
    @State private var monthlyFeeText = ""

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
                Section {
                    TextField("Name (e.g. U16 Girls)", text: $name)
                    TextField("Age category (optional)", text: $ageCategory)
                } header: {
                    Text("Group Info")
                        .foregroundColor(AppTheme.courtBlueLite)
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            colorSwatch(hex)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { themedHeader("Color") }

                Section {
                    HStack(spacing: 16) {
                        genderButton(emojiValue: "👦", label: "Boys / Men")
                        genderButton(emojiValue: "👧", label: "Girls / Women")
                    }
                    .padding(.vertical, 4)
                } header: { themedHeader("Group Type") }

                Section {
                    HStack {
                        TextField("0", text: $monthlyFeeText)
                            .keyboardType(.decimalPad)
                        Text("€ / player")
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                } header: { themedHeader("Monthly Fee") }

                Section {
                    HStack(spacing: 4) {
                        ForEach(0..<7) { d in
                            dayButton(d)
                        }
                    }

                    Toggle("Training time", isOn: $hasTime.animation())

                    if hasTime {
                        DatePicker("Time", selection: $trainingTime, displayedComponents: .hourAndMinute)
                    }
                } header: { themedHeader("Training Schedule") }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.skyBlue)
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

    // MARK: - Helpers

    private func themedHeader(_ text: String) -> some View {
        Text(text)
            .foregroundColor(AppTheme.courtBlueLite)
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
    }

    // MARK: Sub-views

    private func genderButton(emojiValue: String, label: String) -> some View {
        let selected = emoji == emojiValue
        return Button {
            emoji = emojiValue
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                Text(emojiValue).font(.system(size: 48))
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(selected ? .white : Color(.label))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selected ? hexToColor(colorHex) : Color(.secondarySystemGroupedBackground),
                in: .rect(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? hexToColor(colorHex) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

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
        emoji        = (g.emoji == "👦" || g.emoji == "👧") ? g.emoji : "👦"
        selectedDays = Set(g.trainingDays)
        hasTime      = g.trainingTime != nil
        trainingTime = g.trainingTime ?? Date()
        monthlyFeeText = g.monthlyFee > 0 ? formattedFee(g.monthlyFee) : ""
    }

    private func formattedFee(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }

    private func parsedFee() -> Double {
        let normalized = monthlyFeeText
            .trimmed
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private func save() {
        let fee = parsedFee()
        if let g = group {
            g.name         = name.trimmed
            g.ageCategory  = ageCategory.trimmed
            g.colorHex     = colorHex
            g.emoji        = emoji
            g.trainingDays = Array(selectedDays).sorted()
            g.trainingTime = hasTime ? trainingTime : nil
            g.monthlyFee   = fee
        } else {
            let g = TeamGroup(
                name: name.trimmed,
                ageCategory: ageCategory.trimmed,
                colorHex: colorHex,
                emoji: emoji,
                monthlyFee: fee
            )
            g.trainingDays = Array(selectedDays).sorted()
            g.trainingTime = hasTime ? trainingTime : nil
            modelContext.insert(g)
            coach.groups.append(g)
        }
        dismiss()
    }
}
