import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = max(min(geometry.size.width - 40, 520), 0)

            ZStack {
                AuthBackgroundView()

                VStack {
                    Spacer(minLength: 0)

                    GlassCard(cornerRadius: 34) {
                        VStack(spacing: 26) {
                            VStack(spacing: 14) {
                                Text("VolleyTracker")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .layoutPriority(2)

                                Text("Track attendance, fees, and training history with clarity.")
                                    .font(.system(.title3, design: .rounded, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.84))
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .layoutPriority(1)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 14) {
                                PrimaryActionButton(title: "Sign Up", systemImage: "arrow.up.right") {
                                    appState.present(.signUp)
                                }

                                PrimaryActionButton(title: "Log In", isProminent: false) {
                                    appState.present(.login)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: panelWidth)
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 18) + 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
    }
}

private struct AuthBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.12),
                    Color(red: 0.02, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("AuthBackground")
                .resizable()
                .scaledToFill()
                .blur(radius: 14)
                .opacity(0.96)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.22)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 120, y: -240)

            Circle()
                .fill(Color(red: 0.38, green: 0.66, blue: 0.82).opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -140, y: 220)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone 17 Pro")

            WelcomeView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("Smaller iPhone")
        }
    }
}
