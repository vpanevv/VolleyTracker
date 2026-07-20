import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var currentNonce: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("welcomeBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        AppTheme.navy.opacity(0.40),
                        AppTheme.navy.opacity(0.20),
                        AppTheme.navy.opacity(0.82),
                        AppTheme.navy.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                ScrollView {
                    VStack(spacing: 24) {
                        brandHero
                            .padding(.top, 68)

                        Spacer(minLength: 80)

                        authenticationCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, 18)
                    }
                    .frame(minHeight: proxy.size.height)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var brandHero: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.14))
                    .frame(width: 88, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    )
                Image(systemName: "figure.volleyball")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppTheme.sun)
            }

            VStack(spacing: 7) {
                Text("VolleyTracker")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text("Run your team from one court-side command center.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 24)
            }
        }
        .foregroundStyle(.white)
    }

    private var authenticationCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("WELCOME TO THE TEAM")
                    .font(.caption2.weight(.black))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.deepBlue)
                Text("Continue securely")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: 320, alignment: .leading)

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    let nonce = Self.randomNonce()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = Self.sha256(nonce)
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: 320)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    Task { await authStore.signInWithGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle.fill")
                            .foregroundStyle(AppTheme.deepBlue)
                        Text("Continue with Google")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppTheme.ocean.opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 320)
                .disabled(authStore.isLoading)
            }

            if authStore.isLoading {
                ProgressView("Opening your workspace…")
                    .font(.footnote)
                    .tint(AppTheme.ocean)
            }

            if let error = authStore.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.coral)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            Text("By continuing, you agree to securely create or open your VolleyTracker account.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: 370)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 28, y: 14)
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                throw AuthUIError.invalidAppleCredential
            }
            Task { await authStore.signInWithApple(identityToken: token, nonce: nonce) }
        } catch {
            authStore.errorMessage = error.localizedDescription
        }
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
                fatalError("Unable to generate a secure nonce")
            }
            for byte in bytes where remaining > 0 && byte < characters.count {
                result.append(characters[Int(byte)])
                remaining -= 1
            }
        }
        return result
    }
}

private enum AuthUIError: LocalizedError {
    case invalidAppleCredential
    var errorDescription: String? { "Apple did not return a valid identity token." }
}
