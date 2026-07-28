import Foundation
import SwiftUI

// MARK: - Fresh Court design system

enum AppTheme {
    // Legacy names stay in place so every screen adopts the new palette together.
    static let navy = Color(red: 0.09, green: 0.47, blue: 0.91)
    static let deepBlue = Color(red: 0.09, green: 0.47, blue: 0.91)
    static let ocean = Color(red: 0.18, green: 0.66, blue: 1.00)
    static let cyan = Color(red: 0.18, green: 0.84, blue: 0.77)
    static let sun = Color(red: 1.00, green: 0.84, blue: 0.35)
    static let coral = Color(red: 1.00, green: 0.43, blue: 0.38)
    static let success = Color(red: 0.22, green: 0.79, blue: 0.55)

    static let canvas = Color(red: 0.965, green: 0.988, blue: 1.00)
    static let ice = Color(red: 0.91, green: 0.975, blue: 1.00)
    static let surface = Color(uiColor: .secondarySystemBackground).opacity(0.94)
    static let ink = Color(red: 0.08, green: 0.31, blue: 0.53)
    static let shadow = deepBlue.opacity(0.10)

    static let heroGradient = LinearGradient(
        colors: [deepBlue, ocean, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let deepGradient = LinearGradient(
        colors: [deepBlue, ocean, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let energyGradient = LinearGradient(
        colors: [sun, Color(red: 1.00, green: 0.72, blue: 0.28)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let softGradient = LinearGradient(
        colors: [ocean.opacity(0.58), cyan.opacity(0.42)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let hairline = ocean.opacity(0.16)
    static let cornerRadius: CGFloat = 20
    static let fieldCornerRadius: CGFloat = 16
}

// MARK: - Background

struct AuroraBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.025, green: 0.07, blue: 0.14),
                        Color(red: 0.04, green: 0.13, blue: 0.23),
                        Color(red: 0.03, green: 0.20, blue: 0.25)
                    ]
                    : [.white, AppTheme.canvas, AppTheme.ice.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.ocean)
                .frame(width: 360, height: 360)
                .opacity(0.10)
                .blur(radius: 95)
                .offset(x: -170, y: -250)

            Circle()
                .fill(AppTheme.cyan)
                .frame(width: 300, height: 300)
                .opacity(0.10)
                .blur(radius: 90)
                .offset(x: 190, y: 120)

            VolleyballCourtLines()
                .stroke(AppTheme.ocean.opacity(0.055),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(width: 420, height: 660)
                .rotationEffect(.degrees(-14))
                .offset(x: 100, y: 170)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// A calmer surface for information-dense team screens.
struct CourtWorkspaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.02, green: 0.055, blue: 0.12),
                        Color(red: 0.035, green: 0.12, blue: 0.21),
                        Color(red: 0.025, green: 0.16, blue: 0.20)
                    ]
                    : [.white, AppTheme.canvas, AppTheme.ice.opacity(0.62)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(AppTheme.ocean.opacity(0.07))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -170, y: -280)
            Circle()
                .fill(AppTheme.cyan.opacity(0.06))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 180, y: 300)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct VolleyballCourtLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let court = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.08)
        path.addRoundedRect(in: court, cornerSize: CGSize(width: 18, height: 18))
        path.move(to: CGPoint(x: court.minX, y: court.midY))
        path.addLine(to: CGPoint(x: court.maxX, y: court.midY))
        path.move(to: CGPoint(x: court.minX, y: court.midY - court.height * 0.18))
        path.addLine(to: CGPoint(x: court.maxX, y: court.midY - court.height * 0.18))
        path.move(to: CGPoint(x: court.minX, y: court.midY + court.height * 0.18))
        path.addLine(to: CGPoint(x: court.maxX, y: court.midY + court.height * 0.18))
        return path
    }
}

// MARK: - Cards and badges

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = AppTheme.cornerRadius
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.softGradient.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 18, x: 0, y: 10)
    }
}

struct CourtIconBadge: View {
    let icon: String
    var tint: Color = AppTheme.ocean
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(tint.opacity(0.13))
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

struct CourtSectionLabel: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(title))
                .textCase(.uppercase)
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(AppTheme.deepBlue)
            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Fields

struct CourtTextField: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isRequired = false
    var helper: String? = nil
    var contentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .next

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(LocalizedStringKey(label))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if isRequired {
                    Text("Required")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.coral)
                }
            }

            HStack(spacing: 12) {
                CourtIconBadge(icon: icon, tint: isFocused ? AppTheme.cyan : AppTheme.ocean, size: 38)

                TextField(
                    "",
                    text: $text,
                    prompt: Text(LocalizedStringKey(placeholder)).foregroundStyle(.tertiary)
                )
                    .textContentType(contentType)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(capitalization)
                    .submitLabel(submitLabel)
                    .focused($isFocused)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                if !text.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.fieldCornerRadius, style: .continuous)
                    .strokeBorder(isFocused ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(AppTheme.ocean.opacity(0.18)),
                                  lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: isFocused ? AppTheme.cyan.opacity(0.14) : .clear, radius: 12, y: 5)

            if let helper {
                Text(LocalizedStringKey(helper))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

struct CourtTextEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var minimumHeight: CGFloat = 110

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(label))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(LocalizedStringKey(placeholder))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                }
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .focused($isFocused)
            }
            .frame(minHeight: minimumHeight)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.fieldCornerRadius, style: .continuous)
                    .strokeBorder(isFocused ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(AppTheme.ocean.opacity(0.18)),
                                  lineWidth: isFocused ? 2 : 1)
            )
        }
    }
}

// Compatibility wrapper used by existing forms while they adopt CourtTextField.
struct ThemedTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?

    var body: some View {
        HStack(spacing: 14) {
            CourtIconBadge(icon: icon, size: 38)
            TextField(LocalizedStringKey(placeholder), text: $text)
                .textContentType(contentType)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            if !text.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ThemedSectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { CourtSectionLabel(title) }
}

// MARK: - Buttons

struct CourtPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(AppTheme.sun.opacity(0.75))
                    .frame(width: 7, height: 7)
                    .padding(12)
            }
            .shadow(color: AppTheme.deepBlue.opacity(isEnabled ? 0.28 : 0), radius: 14, y: 8)
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.42)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CourtSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.deepBlue)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(AppTheme.ocean.opacity(0.24), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

// MARK: - Helpers

extension View {
    func heroGradientForeground() -> some View {
        foregroundStyle(AppTheme.heroGradient)
    }
}

enum Greeting {
    static func forNow() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }
}

extension Color {
    init(teamHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        if cleaned.count == 6 {
            red = value >> 16
            green = value >> 8 & 0xFF
            blue = value & 0xFF
        } else {
            red = 0
            green = 122
            blue = 255
        }

        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
