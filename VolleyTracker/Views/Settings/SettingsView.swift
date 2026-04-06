import SwiftUI

struct SettingsView: View {
    let coach: Coach
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("coachName") private var savedCoachName = ""

    @State private var showingEditProfile = false

    private func themedHeader(_ text: String) -> some View {
        Text(text)
            .foregroundColor(AppTheme.courtBlueLite)
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
    }

    var body: some View {
        NavigationStack {
            List {
                // Coach profile card
                Section {
                    HStack(spacing: 14) {
                        PlayerAvatarView(photoData: coach.photoData, name: coach.name, size: 56)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(coach.name)
                                .font(.headline)
                                .foregroundStyle(Color(.label))
                            if !coach.club.isEmpty {
                                Text(coach.club)
                                    .font(.subheadline)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }

                        Spacer()

                        Button("Edit") { showingEditProfile = true }
                            .foregroundColor(AppTheme.activeBlue)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.cardSurface)
                }

                Section {
                    let totalPlayers  = coach.groups.reduce(0) { $0 + $1.players.count }
                    let totalSessions = coach.groups.reduce(0) { $0 + $1.trainingSessions.count }

                    LabeledContent("Groups", value: "\(coach.groups.count)")
                    LabeledContent("Total Players", value: "\(totalPlayers)")
                    LabeledContent("Training Sessions", value: "\(totalSessions)")
                } header: { themedHeader("Statistics") }

                Section {
                    LabeledContent("Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledContent("Build",
                        value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                } header: { themedHeader("App") }

                Section {
                    Button(role: .destructive) { logOut() } label: {
                        Text("Log Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.skyBlue)
            .navigationTitle("Settings")
            .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
