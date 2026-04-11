import SwiftUI
import SwiftData

struct LoginView: View {
    @Query private var coaches: [Coach]
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("coachName") private var savedCoachName = ""

    @State private var name = ""
    @State private var errorMessage = ""
    @State private var orbPulse = false
    @State private var sparkleRotation = 0.0

    private var canSubmit: Bool { !name.trimmed.isEmpty }

    private var firstName: String {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else { return "" }
        return trimmed.split(separator: " ").first.map(String.init) ?? trimmed
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Hero badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.footnote.weight(.bold))
                        Text("Welcome back")
                            .font(.footnote.weight(.bold))
                            .tracking(0.5)
                    }
                    .heroGradientForeground()
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // Form card
                    VStack(spacing: 0) {
                        ThemedTextField(icon: "person.fill",
                                        placeholder: "Your name",
                                        text: $name,
                                        contentType: .name)
                            .onChange(of: name) { _, _ in errorMessage = "" }
                    }
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.10),
                            radius: 18, x: 0, y: 10)
                    .padding(.horizontal, 16)

                    if !errorMessage.isEmpty {
                        errorCard
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Text("Enter the name on your coach profile to pick up right where you left off.")
                            .font(.footnote)
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(.horizontal, 24)
                    }

                    // Animated glowing orb
                    animatedOrb
                        .padding(.top, 8)

                    // What's waiting for you
                    welcomeBackCard
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
        .navigationTitle("Welcome Back")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button(action: login) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Log In")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.heroGradient, in: Capsule())
                .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.4),
                        radius: 16, x: 0, y: 8)
                .opacity(canSubmit ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Error card

    private var errorCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.red.opacity(0.18))
                    .frame(width: 36, height: 36)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.55), lineWidth: 1)
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.red)
            }
            Text(errorMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(.label))
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.red.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color.red.opacity(0.18), radius: 16, x: 0, y: 8)
    }

    // MARK: - Animated orb

    private var animatedOrb: some View {
        ZStack {
            // Outer soft glow
            Circle()
                .fill(AppTheme.heroGradient)
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .opacity(orbPulse ? 0.55 : 0.30)

            // Concentric gradient rings
            ForEach(0..<3) { i in
                Circle()
                    .strokeBorder(
                        AppTheme.heroGradient.opacity(0.5 - Double(i) * 0.12),
                        lineWidth: 1
                    )
                    .frame(
                        width: 120 + CGFloat(i) * 22,
                        height: 120 + CGFloat(i) * 22
                    )
                    .scaleEffect(orbPulse ? 1.05 : 0.95)
            }

            // Orbiting sparkle
            ZStack {
                ForEach(0..<6) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .heroGradientForeground()
                        .offset(y: -72)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
            }
            .rotationEffect(.degrees(sparkleRotation))

            // Core glass disc
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle().strokeBorder(
                            AppTheme.heroGradient.opacity(0.9),
                            lineWidth: 1.5
                        )
                    )
                    .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.45),
                            radius: 20, x: 0, y: 10)

                Image(systemName: firstName.isEmpty ? "lock.fill" : "hand.wave.fill")
                    .font(.system(size: 34, weight: .bold))
                    .heroGradientForeground()
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.pulse, options: .repeating)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
    }

    // MARK: - Welcome back card

    private var welcomeBackCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                Text(firstName.isEmpty
                     ? "WE MISSED YOU"
                     : "WELCOME BACK, \(firstName.uppercased())")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .contentTransition(.interpolate)
            }
            .heroGradientForeground()

            VStack(spacing: 10) {
                WelcomeRow(icon: "person.3.fill",
                           title: "Your groups are waiting",
                           subtitle: "Teams, rosters, and colors exactly where you left them.")
                WelcomeRow(icon: "calendar",
                           title: "Training sessions ready",
                           subtitle: "Every scheduled practice and attendance log preserved.")
                WelcomeRow(icon: "eurosign.circle.fill",
                           title: "Fee history preserved",
                           subtitle: "Payment records, exports, and monthly totals intact.")
            }
        }
        .padding(18)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.softGradient.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.50, green: 0.30, blue: 1.00).opacity(0.18),
                radius: 24, x: 0, y: 14)
    }

    private func login() {
        let trimmed = name.trimmed
        if coaches.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) != nil {
            savedCoachName = trimmed
            isLoggedIn = true
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                errorMessage = "No coach found with that name."
            }
        }
    }
}

// MARK: - WelcomeRow

private struct WelcomeRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(AppTheme.heroGradient.opacity(0.2))
                    .frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(AppTheme.heroGradient.opacity(0.7), lineWidth: 1)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .heroGradientForeground()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.label))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "sparkle")
                .font(.caption2.weight(.bold))
                .heroGradientForeground()
                .opacity(0.6)
        }
    }
}
