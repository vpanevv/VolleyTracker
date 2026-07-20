import AuthenticationServices
import Foundation
import Supabase

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    private let client = SupabaseConfig.client

    init() {
        Task { await observeSession() }
    }

    func signInWithGoogle() async {
        await perform {
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: SupabaseConfig.callbackURL
            )
        }
    }

    func signInWithApple(identityToken: String, nonce: String) async {
        await perform {
            _ = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nonce
                )
            )
        }
    }

    func signOut() async {
        await perform {
            try await client.auth.signOut()
        }
    }

    private func observeSession() async {
        session = try? await client.auth.session
        isLoading = false

        for await (_, newSession) in await client.auth.authStateChanges {
            session = newSession
            isLoading = false
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
