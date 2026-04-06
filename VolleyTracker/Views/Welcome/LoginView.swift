import SwiftUI
import SwiftData

struct LoginView: View {
    @Query private var coaches: [Coach]
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("coachName") private var savedCoachName = ""

    @State private var name = ""
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section {
                TextField("Your Name", text: $name)
                    .textContentType(.name)
                    .onChange(of: name) { _, _ in errorMessage = "" }
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(AppTheme.dangerRed)
                        .font(.subheadline)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.skyBlue)
        .navigationTitle("Welcome Back")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button(action: login) {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.activeBlue)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(name.trimmed.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    private func login() {
        let trimmed = name.trimmed
        if coaches.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) != nil {
            savedCoachName = trimmed
            isLoggedIn = true
        } else {
            errorMessage = "No coach found with that name."
        }
    }
}
