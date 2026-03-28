import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    enum AuthDestination: String, Identifiable {
        case signUp
        case login

        var id: String { rawValue }
    }

    @Published var storedCoach: Coach?
    @Published var signedInCoach: Coach?
    @Published var presentedAuthDestination: AuthDestination?

    func present(_ destination: AuthDestination) {
        presentedAuthDestination = destination
    }

    func dismissAuth() {
        presentedAuthDestination = nil
    }

    func registerCoach(
        fullName: String,
        ageText: String,
        teamName: String,
        email: String,
        password: String,
        confirmPassword: String
    ) throws {
        let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTeam = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedName.isEmpty,
              !ageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !normalizedTeam.isEmpty,
              !normalizedEmail.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            throw AuthError.missingFields
        }

        guard let age = Int(ageText), (16...100).contains(age) else {
            throw AuthError.invalidAge
        }

        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            throw AuthError.invalidEmail
        }

        guard password == confirmPassword else {
            throw AuthError.passwordMismatch
        }

        let coach = Coach(
            fullName: normalizedName,
            age: age,
            teamName: normalizedTeam,
            email: normalizedEmail,
            password: password
        )

        storedCoach = coach
        signedInCoach = coach
        dismissAuth()
    }

    func logIn(email: String, password: String) throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            throw AuthError.missingFields
        }

        guard let storedCoach else {
            throw AuthError.noRegisteredCoach
        }

        guard storedCoach.email == normalizedEmail, storedCoach.password == password else {
            throw AuthError.invalidCredentials
        }

        signedInCoach = storedCoach
        dismissAuth()
    }

    func logOut() {
        signedInCoach = nil
    }
}

enum AuthError: LocalizedError, Equatable {
    case missingFields
    case invalidAge
    case invalidEmail
    case passwordMismatch
    case noRegisteredCoach
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .missingFields:
            return "Fill in all required fields to continue."
        case .invalidAge:
            return "Enter a valid coach age between 16 and 100."
        case .invalidEmail:
            return "Enter a valid email address."
        case .passwordMismatch:
            return "Passwords need to match."
        case .noRegisteredCoach:
            return "Create a coach profile first, then log in with those credentials."
        case .invalidCredentials:
            return "That email and password combination doesn’t match this session."
        }
    }
}
