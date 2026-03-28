import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            if let coach = appState.signedInCoach {
                DashboardView(coach: coach)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                WelcomeView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.44, dampingFraction: 0.9), value: appState.signedInCoach?.id)
        .sheet(item: authBinding) { destination in
            NavigationStack {
                switch destination {
                case .signUp:
                    SignUpView()
                case .login:
                    LoginView()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    private var authBinding: Binding<AppState.AuthDestination?> {
        Binding(
            get: { appState.presentedAuthDestination },
            set: { appState.presentedAuthDestination = $0 }
        )
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState())
    }
}
