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
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        // Sparkle eyebrow
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.footnote.weight(.bold))
                            Text(isEditing ? "Update group" : "Create new group")
                                .font(.footnote.weight(.bold))
                                .tracking(0.5)
                        }
                        .heroGradientForeground()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        // Group info
                        themedSection("GROUP INFO") {
                            VStack(spacing: 0) {
                                ThemedTextField(icon: "textformat",
                                                placeholder: "Name (e.g. U16 Girls)",
                                                text: $name,
                                                contentType: nil)
                                Divider().padding(.leading, 54)
                                ThemedTextField(icon: "number",
                                                placeholder: "Age category (optional)",
                                                text: $ageCategory,
                                                contentType: nil)
                            }
                        }

                        // Color
                        themedSection("COLOR") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6),
                                      spacing: 14) {
                                ForEach(colors, id: \.self) { hex in
                                    colorSwatch(hex)
                                }
                            }
                            .padding(16)
                        }

                        // Group type
                        themedSection("GROUP TYPE") {
                            HStack(spacing: 12) {
                                genderButton(emojiValue: "👦", label: "Boys / Men")
                                genderButton(emojiValue: "👧", label: "Girls / Women")
                            }
                            .padding(16)
                        }

                        // Monthly fee
                        themedSection("MONTHLY FEE") {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.heroGradient.opacity(0.18))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "eurosign.circle.fill")
                                        .font(.footnote.weight(.bold))
                                        .heroGradientForeground()
                                }
                                TextField("0", text: $monthlyFeeText)
                                    .keyboardType(.decimalPad)
                                    .font(.body)
                                    .foregroundStyle(Color(.label))
                                Text("€ / player")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }

                        // Training schedule
                        themedSection("TRAINING SCHEDULE") {
                            VStack(spacing: 14) {
                                HStack(spacing: 6) {
                                    ForEach(0..<7) { d in
                                        dayButton(d)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 14)

                                Divider().padding(.horizontal, 16)

                                Toggle(isOn: $hasTime.animation()) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(AppTheme.heroGradient.opacity(0.18))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "clock.fill")
                                                .font(.footnote.weight(.bold))
                                                .heroGradientForeground()
                                        }
                                        Text("Training time")
                                            .foregroundStyle(Color(.label))
                                    }
                                }
                                .tint(Color(red: 0.24, green: 0.40, blue: 1.00))
                                .padding(.horizontal, 16)

                                if hasTime {
                                    Divider().padding(.horizontal, 16)
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(AppTheme.heroGradient.opacity(0.18))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "clock.badge")
                                                .font(.footnote.weight(.bold))
                                                .heroGradientForeground()
                                        }
                                        Text("Time")
                                            .foregroundStyle(Color(.label))
                                        Spacer()
                                        DatePicker("", selection: $trainingTime,
                                                   displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .tint(Color(red: 0.24, green: 0.40, blue: 1.00))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 14)
                                } else {
                                    Spacer().frame(height: 14)
                                }
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
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
                            .opacity(name.trimmed.isEmpty ? 0.5 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmed.isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    // MARK: Themed section wrapper

    @ViewBuilder
    private func themedSection<Content: View>(_ title: String,
                                              @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ThemedSectionLabel(title)
                .padding(.horizontal, 20)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.10),
                        radius: 18, x: 0, y: 10)
                .padding(.horizontal, 16)
        }
    }

    // MARK: Sub-views

    private func genderButton(emojiValue: String, label: String) -> some View {
        let selected = emoji == emojiValue
        return Button {
            emoji = emojiValue
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                Text(emojiValue).font(.system(size: 44))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selected ? .white : Color(.label))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                selected ? AnyShapeStyle(AppTheme.heroGradient)
                         : AnyShapeStyle(Color.white.opacity(0.01)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? AnyShapeStyle(Color.clear)
                                            : AnyShapeStyle(AppTheme.softGradient.opacity(0.5)),
                                  lineWidth: 1)
            )
            .shadow(color: selected
                    ? Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.35)
                    : Color.clear,
                    radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func colorSwatch(_ hex: String) -> some View {
        let hexColor = hexToColor(hex)
        let selected = hex == colorHex
        return ZStack {
            Circle()
                .fill(hexColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: selected ? 0 : 1)
                )
            if selected {
                Circle()
                    .strokeBorder(AppTheme.heroGradient, lineWidth: 3)
                    .frame(width: 46, height: 46)
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
        }
        .shadow(color: hexColor.opacity(selected ? 0.5 : 0.15),
                radius: selected ? 10 : 4, x: 0, y: 3)
        .onTapGesture {
            colorHex = hex
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func dayButton(_ d: Int) -> some View {
        let selected = selectedDays.contains(d)
        return Text(dayLetters[d])
            .font(.footnote.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(
                selected ? AnyShapeStyle(AppTheme.heroGradient)
                         : AnyShapeStyle(Color.white.opacity(0.01)),
                in: Circle()
            )
            .overlay(
                Circle().strokeBorder(
                    selected ? AnyShapeStyle(Color.clear)
                             : AnyShapeStyle(AppTheme.softGradient.opacity(0.5)),
                    lineWidth: 1
                )
            )
            .foregroundStyle(selected ? .white : Color(.secondaryLabel))
            .shadow(color: selected
                    ? Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.35)
                    : Color.clear,
                    radius: 8, x: 0, y: 4)
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
