import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Log In")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Use the coach profile created in this session.")
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
                            InputField(title: "Email", prompt: "coach@example.com", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                                .focused($focusedField, equals: .email)

                            InputField(title: "Password", prompt: "Enter password", text: $password, textContentType: .password, submitLabel: .done, isSecure: true)
                                .focused($focusedField, equals: .password)

                            if let errorMessage {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.orange.opacity(0.95))
                                    Text(errorMessage)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.84))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.orange.opacity(0.16), lineWidth: 1)
                                }
                            }

                            PrimaryActionButton(title: "Log In", systemImage: "arrow.right") {
                                logIn()
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
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                logIn()
            case .none:
                break
            }
        }
    }

    private func logIn() {
        do {
            try appState.logIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()

        return Group {
            NavigationStack {
                LoginView()
                    .environmentObject(appState)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Default")

            NavigationStack {
                LoginView()
                    .environmentObject(appState)
            }
            .preferredColorScheme(.dark)
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("Smaller iPhone")
        }
    }
}
