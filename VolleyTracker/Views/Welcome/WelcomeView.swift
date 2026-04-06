import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: Background image
                Image("welcomeBG")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Layer 2: Light dark overlay — no blur
                Color.black.opacity(0.30)
                    .ignoresSafeArea()

                // Layer 3: Content
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)

                        VStack(spacing: 8) {
                            Text("VolleyTracker")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Track your team. Own your game.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink(destination: CreateAccountView()) {
                            Text("Get Started")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(AppTheme.courtBlue)
                                .cornerRadius(14)
                        }

                        NavigationLink(destination: LoginView()) {
                            Text("I Already Have an Account")
                                .font(.body.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(.ultraThinMaterial)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}
