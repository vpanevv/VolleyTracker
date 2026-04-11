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

                // Layer 2: Dark overlay — no blur
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                // Layer 3: Content — grouped slightly above center
                VStack(spacing: 0) {
                    Spacer()
                    Spacer()

                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .padding(.bottom, 16)

                    Text("VolleyTracker")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 4)

                    Text("Track your team. Own your game.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 40)

                    VStack(spacing: 14) {
                        NavigationLink(destination: CreateAccountView()) {
                            Text("Make an account")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }

                        NavigationLink(destination: LoginView()) {
                            Text("Already have an account?")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }

                    Spacer()
                }
            }
        }
    }
}
