import SwiftUI

struct SettingsView: View {
    let coach: Coach
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("coachName") private var savedCoachName = ""

    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                List {
                    // AI-style profile hero card
                    Section {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.heroGradient)
                                    .frame(width: 96, height: 96)
                                    .blur(radius: 8)
                                    .opacity(0.6)
                                PlayerAvatarView(photoData: coach.photoData, name: coach.name, size: 88)
                                    .overlay(
                                        Circle().strokeBorder(
                                            AppTheme.heroGradient,
                                            lineWidth: 3
                                        )
                                    )
                            }
                            .padding(.top, 8)

                            VStack(spacing: 4) {
                                Text(coach.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(Color(.label))
                                if !coach.club.isEmpty {
                                    Text(coach.club)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                            }

                            Button { showingEditProfile = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                    Text("Edit profile")
                                }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 9)
                                .background(AppTheme.heroGradient, in: Capsule())
                                .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.35),
                                        radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
                                )
                        )
                        .listRowSeparator(.hidden)
                    }

                    Section {
                        let totalPlayers  = coach.groups.reduce(0) { $0 + $1.players.count }
                        let totalSessions = coach.groups.reduce(0) { $0 + $1.trainingSessions.count }

                        StatRow(icon: "person.3.fill",
                                tint: Color(red: 0.24, green: 0.40, blue: 1.00),
                                label: "Groups",
                                value: "\(coach.groups.count)")
                        StatRow(icon: "figure.volleyball",
                                tint: Color(red: 0.55, green: 0.28, blue: 1.00),
                                label: "Total Players",
                                value: "\(totalPlayers)")
                        StatRow(icon: "calendar",
                                tint: Color(red: 1.00, green: 0.35, blue: 0.70),
                                label: "Training Sessions",
                                value: "\(totalSessions)")
                    } header: {
                        SectionHeader(title: "STATISTICS")
                    }

                    Section {
                        StatRow(icon: "app.badge",
                                tint: .teal,
                                label: "Version",
                                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        StatRow(icon: "hammer.fill",
                                tint: .indigo,
                                label: "Build",
                                value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    } header: {
                        SectionHeader(title: "APP")
                    }

                    Section {
                        Button(role: .destructive) { logOut() } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
                                )
                        )
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(coach: coach)
            }
        }
    }

    private func logOut() {
        isLoggedIn = false
        savedCoachName = ""
    }
}

// MARK: - StatRow

private struct StatRow: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(tint)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(.label))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SectionHeader

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.heroGradient)
    }
}
