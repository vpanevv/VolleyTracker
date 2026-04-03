import SwiftUI

struct SettingsView: View {
    let coach: Coach
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("coachName") private var savedCoachName = ""

    @State private var showingEditProfile = false

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
                            .foregroundStyle(.blue)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 4)
                }

                Section("Statistics") {
                    let totalPlayers  = coach.groups.reduce(0) { $0 + $1.players.count }
                    let totalSessions = coach.groups.reduce(0) { $0 + $1.trainingSessions.count }

                    LabeledContent("Groups", value: "\(coach.groups.count)")
                    LabeledContent("Total Players", value: "\(totalPlayers)")
                    LabeledContent("Training Sessions", value: "\(totalSessions)")
                }

                Section("App") {
                    LabeledContent("Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledContent("Build",
                        value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }

                Section {
                    Button(role: .destructive) { logOut() } label: {
                        Text("Log Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbarBackground(.visible, for: .navigationBar)
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
