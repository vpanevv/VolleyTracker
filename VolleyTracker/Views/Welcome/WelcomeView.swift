import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    VStack(spacing: 8) {
                        Text("VolleyTracker")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color(.label))

                        Text("Track your team. Own your game.")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: CreateAccountView()) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .clipShape(.rect(cornerRadius: 14))

                    NavigationLink(destination: LoginView()) {
                        Text("I Already Have an Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
