import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    let coach: Coach

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(geometry.size.width - 48, 0)

            ZStack {
                DashboardBackgroundView()

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let now = context.date

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            VStack(spacing: 12) {
                                Text(now.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.76))
                                    .frame(width: contentWidth)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(now.formatted(.dateTime.hour().minute()))
                                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                                    .frame(width: contentWidth)

                                Text("Welcome coach, \(coach.fullName)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: contentWidth)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .layoutPriority(2)

                                Text("You don’t have any groups yet.")
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.76))
                                    .frame(width: contentWidth)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 32)

                            GlassCard(cornerRadius: 30) {
                                VStack(spacing: 18) {
                                    Label("Groups", systemImage: "square.grid.2x2")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .center)

                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(.white.opacity(0.06))
                                        .frame(maxWidth: .infinity, minHeight: 196)
                                        .overlay {
                                            VStack(spacing: 12) {
                                                Image(systemName: "person.3.sequence.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundStyle(.white.opacity(0.68))

                                                Text("Your first training groups will appear here.")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white.opacity(0.72))
                                                    .frame(maxWidth: .infinity)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(nil)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.horizontal, 24)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(width: contentWidth)

                            Spacer(minLength: 28)

                            Button("Log Out") {
                                appState.logOut()
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.76))
                            .frame(width: contentWidth)
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, geometry.safeAreaInsets.top + 28)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct DashboardBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.1),
                    Color(red: 0.1, green: 0.12, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("AuthBackground")
                .resizable()
                .scaledToFill()
                .blur(radius: 22)
                .opacity(0.54)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.05),
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 85)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color(red: 0.38, green: 0.66, blue: 0.82).opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 95)
                .offset(x: -130, y: 250)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.signedInCoach = Coach(
            fullName: "Vladimir Stoyanov Petrov",
            age: 34,
            teamName: "Falcons",
            email: "coach@example.com",
            password: "secret123"
        )

        return Group {
            DashboardView(coach: appState.signedInCoach!)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone 17 Pro")

            DashboardView(coach: appState.signedInCoach!)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("Smaller iPhone")
        }
    }
}
