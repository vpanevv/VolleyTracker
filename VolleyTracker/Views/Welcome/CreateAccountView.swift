import SwiftUI
import SwiftData

struct CreateAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("coachName") private var savedCoachName = ""

    @State private var name = ""
    @State private var club = ""

    private var canSubmit: Bool { !name.trimmed.isEmpty && !club.trimmed.isEmpty }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Hero badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.footnote.weight(.bold))
                        Text("Let's set you up")
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
                        Divider().padding(.leading, 54)
                        ThemedTextField(icon: "building.2.fill",
                                        placeholder: "Club / Organization",
                                        text: $club,
                                        contentType: nil)
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

                    Text("These are the only details needed to set up your coach profile.")
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 24)

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button(action: createAccount) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Get Started")
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

    private func createAccount() {
        let coach = Coach(name: name.trimmed, club: club.trimmed)
        modelContext.insert(coach)
        savedCoachName = coach.name
        isLoggedIn = true
    }
}
