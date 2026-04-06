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
        Form {
            Section {
                TextField("Your Name", text: $name)
                    .textContentType(.name)
                TextField("Club / Organization", text: $club)
            } footer: {
                Text("These are the only details needed to set up your coach profile.")
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            Button(action: createAccount) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!canSubmit)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    private func createAccount() {
        let coach = Coach(name: name.trimmed, club: club.trimmed)
        modelContext.insert(coach)
        savedCoachName = coach.name
        isLoggedIn = true
    }
}
