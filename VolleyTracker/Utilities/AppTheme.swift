import SwiftUI

// MARK: - Brand gradients

enum AppTheme {
    /// Signature blue → indigo → pink "AI" gradient used for accents,
    /// gradient text, primary buttons, and icon badges.
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.24, green: 0.40, blue: 1.00), // electric blue
            Color(red: 0.50, green: 0.30, blue: 1.00), // violet
            Color(red: 1.00, green: 0.35, blue: 0.70)  // pink
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Softer supporting gradient for cards / outlines.
    static let softGradient = LinearGradient(
        colors: [
            Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.55),
            Color(red: 0.90, green: 0.30, blue: 0.70).opacity(0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Used for a subtle outline on glass cards.
    static let hairline = Color.white.opacity(0.22)
}

// MARK: - Aurora background

/// Blurry blob "mesh" background reminiscent of modern AI apps.
/// Sits behind list / scroll content; respects light & dark mode.
struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Base tint
            (scheme == .dark
             ? Color(red: 0.04, green: 0.05, blue: 0.10)
             : Color(red: 0.96, green: 0.97, blue: 1.00))
                .ignoresSafeArea()

            // Blob 1 — blue
            Circle()
                .fill(Color(red: 0.24, green: 0.40, blue: 1.00))
                .frame(width: 380, height: 380)
                .opacity(scheme == .dark ? 0.35 : 0.22)
                .blur(radius: 90)
                .offset(x: -140, y: -220)

            // Blob 2 — violet
            Circle()
                .fill(Color(red: 0.55, green: 0.28, blue: 1.00))
                .frame(width: 320, height: 320)
                .opacity(scheme == .dark ? 0.30 : 0.18)
                .blur(radius: 90)
                .offset(x: 170, y: -80)

            // Blob 3 — pink
            Circle()
                .fill(Color(red: 1.00, green: 0.35, blue: 0.70))
                .frame(width: 360, height: 360)
                .opacity(scheme == .dark ? 0.28 : 0.16)
                .blur(radius: 100)
                .offset(x: -80, y: 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Glass card style

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppTheme.softGradient.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.12),
                    radius: 24, x: 0, y: 12)
    }
}

// MARK: - Gradient text helper

extension View {
    /// Fills any foreground-styleable view (Text, Image) with the hero gradient.
    func heroGradientForeground() -> some View {
        self.foregroundStyle(AppTheme.heroGradient)
    }
}

// MARK: - Greeting helper

enum Greeting {
    static func forNow() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Hello"
        }
    }
}
