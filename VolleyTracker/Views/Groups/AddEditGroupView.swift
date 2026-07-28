import SwiftUI
import SwiftData

struct AddEditGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let coach: Coach
    var group: TeamGroup?

    @State private var name = ""
    @State private var ageCategory = ""
    @State private var colorHex = "#0A6EC2"
    @State private var emoji = "👦"
    @State private var selectedDays: Set<Int> = []
    @State private var trainingTime = Date()
    @State private var hasTime = false
    @State private var monthlyFeeText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @AppStorage(AppCurrency.storageKey) private var currencyCode = AppCurrency.eur.rawValue

    private var isEditing: Bool { group != nil }
    private var selectedCurrency: AppCurrency {
        AppCurrency(rawValue: currencyCode) ?? .eur
    }

    private let colors = [
        "#0A6EC2","#0464A8","#18C2C2","#12A873",
        "#FFC745","#FF941A","#F76350","#D74368",
        "#4356B8","#127E93","#876E55","#59636E"
    ]

    private let dayLetters = ["Su","Mo","Tu","We","Th","Fr","Sa"]

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

                        VStack(alignment: .leading, spacing: 13) {
                            CourtSectionLabel("Team details", subtitle: "Give this squad a clear identity.")
                            CourtTextField(
                                label: "Team name",
                                placeholder: "e.g. U16 Girls",
                                icon: "person.3.fill",
                                text: $name,
                                isRequired: true,
                                capitalization: .words
                            )
                            CourtTextField(
                                label: "Age category",
                                placeholder: "Optional",
                                icon: "number",
                                text: $ageCategory,
                                capitalization: .characters
                            )
                        }
                        .padding(.horizontal, 16)

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

                        VStack(alignment: .leading, spacing: 13) {
                            CourtSectionLabel("Monthly fee", subtitle: "Used for collection tracking and reports.")
                            CourtTextField(
                                label: "Fee per player (\(selectedCurrency.symbol))",
                                placeholder: "0",
                                icon: "banknote.fill",
                                text: $monthlyFeeText,
                                keyboardType: .decimalPad,
                                capitalization: .never,
                                submitLabel: .done
                            )
                        }
                        .padding(.horizontal, 16)

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
                                .tint(AppTheme.ocean)
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
                                            .tint(AppTheme.ocean)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 14)
                                } else {
                                    Spacer().frame(height: 14)
                                }
                            }
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "icloud.slash.fill")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.coral)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(
                Text(LocalizedStringKey(isEditing ? "Edit Group" : "New Group"))
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(.secondaryLabel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        HStack(spacing: 6) {
                            if isSaving { ProgressView().tint(.white) }
                            Text(isSaving ? "Saving" : "Save")
                        }
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(AppTheme.heroGradient, in: Capsule())
                        .shadow(color: AppTheme.deepBlue.opacity(0.28),
                                radius: 10, x: 0, y: 5)
                        .opacity(name.trimmed.isEmpty ? 0.5 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmed.isEmpty || isSaving)
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
                .shadow(color: AppTheme.navy.opacity(0.10),
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
                    ? AppTheme.deepBlue.opacity(0.28)
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
                    ? AppTheme.deepBlue.opacity(0.28)
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

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        let fee = parsedFee()
        let savedGroup: TeamGroup
        if let group {
            group.name = name.trimmed
            group.ageCategory = ageCategory.trimmed
            group.colorHex = colorHex
            group.emoji = emoji
            group.trainingDays = Array(selectedDays).sorted()
            group.trainingTime = hasTime ? trainingTime : nil
            group.monthlyFee = fee
            savedGroup = group
        } else {
            let group = TeamGroup(
                name: name.trimmed,
                ageCategory: ageCategory.trimmed,
                colorHex: colorHex,
                emoji: emoji,
                monthlyFee: fee
            )
            group.trainingDays = Array(selectedDays).sorted()
            group.trainingTime = hasTime ? trainingTime : nil
            modelContext.insert(group)
            coach.groups.append(group)
            savedGroup = group
        }

        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()

        Task { try? await CloudDataService.shared.upsertGroup(savedGroup) }
        isSaving = false
    }
}
