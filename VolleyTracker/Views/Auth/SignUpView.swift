import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var age = ""
    @State private var teamName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field {
        case fullName
        case age
        case teamName
        case email
        case password
        case confirmPassword
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Create Coach Profile")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Set up your first coach account locally for this MVP flow.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.74))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GlassCard {
                        VStack(spacing: 18) {
                            fieldGroup

                            if let errorMessage {
                                errorBanner(message: errorMessage)
                            }

                            PrimaryActionButton(title: "Create Coach Profile", systemImage: "checkmark.circle.fill") {
                                register()
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, max(geometry.safeAreaInsets.top, 18) + 12)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 24) + 36)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .background(FormBackgroundView())
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onSubmit(advanceFocus)
    }

    private var fieldGroup: some View {
        Group {
            InputField(title: "Full Name", prompt: "Enter your name", text: $fullName, textContentType: .name)
                .focused($focusedField, equals: .fullName)
            InputField(title: "Age", prompt: "Enter age", text: $age, keyboardType: .numberPad, submitLabel: .next)
                .focused($focusedField, equals: .age)
            InputField(title: "Team Name", prompt: "Enter team name", text: $teamName, textContentType: .organizationName)
                .focused($focusedField, equals: .teamName)
            InputField(title: "Email", prompt: "coach@example.com", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                .focused($focusedField, equals: .email)
            InputField(title: "Password", prompt: "Create password", text: $password, textContentType: .newPassword, submitLabel: .next, isSecure: true)
                .focused($focusedField, equals: .password)
            InputField(title: "Confirm Password", prompt: "Repeat password", text: $confirmPassword, textContentType: .newPassword, submitLabel: .done, isSecure: true)
                .focused($focusedField, equals: .confirmPassword)
        }
    }

    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red.opacity(0.95))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.84))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.red.opacity(0.16), lineWidth: 1)
        }
    }

    private func advanceFocus() {
        switch focusedField {
        case .fullName:
            focusedField = .age
        case .age:
            focusedField = .teamName
        case .teamName:
            focusedField = .email
        case .email:
            focusedField = .password
        case .password:
            focusedField = .confirmPassword
        case .confirmPassword:
            register()
        case .none:
            break
        }
    }

    private func register() {
        do {
            try appState.registerCoach(
                fullName: fullName,
                ageText: age,
                teamName: teamName,
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                SignUpView()
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Default")

            NavigationStack {
                SignUpView()
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("Smaller iPhone")
        }
    }
}
