import SwiftUI

struct SettingsView: View {
    let coach: Coach
    @EnvironmentObject private var authStore: AuthStore

    @State private var showingEditProfile = false
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage.rawValue
    @AppStorage(AppAppearance.storageKey) private var appearanceCode = AppAppearance.system.rawValue
    @AppStorage(AppCurrency.storageKey) private var currencyCode = AppCurrency.eur.rawValue

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
                                Text(LocalizedStringKey(coach.role.rawValue))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.deepBlue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.sun.opacity(0.28), in: Capsule())
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
                                .shadow(color: AppTheme.deepBlue.opacity(0.28),
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
                                tint: AppTheme.ocean,
                                label: "Groups",
                                value: "\(coach.groups.count)")
                        StatRow(icon: "figure.volleyball",
                                tint: AppTheme.cyan,
                                label: "Total Players",
                                value: "\(totalPlayers)")
                        StatRow(icon: "calendar",
                                tint: AppTheme.sun,
                                label: "Training Sessions",
                                value: "\(totalSessions)")
                    } header: {
                        SectionHeader(title: "STATISTICS")
                    }

                    Section {
                        PreferencePickerRow(icon: "globe", tint: AppTheme.ocean) {
                            Picker("Language", selection: $languageCode) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.nativeName).tag(language.rawValue)
                                }
                            }
                        }

                        PreferencePickerRow(icon: "moon.stars.fill", tint: AppTheme.deepBlue) {
                            Picker("Appearance", selection: $appearanceCode) {
                                ForEach(AppAppearance.allCases) { appearance in
                                    Label(
                                        LocalizedStringKey(appearance.title),
                                        systemImage: appearance.icon
                                    )
                                    .tag(appearance.rawValue)
                                }
                            }
                        }

                        PreferencePickerRow(icon: "banknote.fill", tint: AppTheme.success) {
                            Picker("Fee currency", selection: $currencyCode) {
                                ForEach(AppCurrency.allCases) { currency in
                                    Text("\(currency.title) · \(currency.symbol)")
                                        .tag(currency.rawValue)
                                }
                            }
                        }
                    } header: {
                        SectionHeader(title: "PREFERENCES")
                    } footer: {
                        Text("Changing currency updates labels only; existing amounts are not converted.")
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
            .navigationTitle(Text("Profile"))
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(coach: coach)
            }
        }
    }

    private func logOut() {
        Task { await authStore.signOut() }
    }
}

private struct PreferencePickerRow<Content: View>: View {
    let icon: String
    let tint: Color
    @ViewBuilder let content: () -> Content

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

            content()
                .pickerStyle(.menu)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - StatRow

private struct StatRow: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
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
    let title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.heroGradient)
    }
}
