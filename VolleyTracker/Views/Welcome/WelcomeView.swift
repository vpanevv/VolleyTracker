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
                            Text("Get Started")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.blue)
                                .clipShape(.rect(cornerRadius: 26))
                        }

                        NavigationLink(destination: LoginView()) {
                            Text("I Already Have an Account")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(.ultraThinMaterial)
                                .clipShape(.rect(cornerRadius: 26))
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
        }
    }
}
