import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isProminent: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.headline.weight(.semibold))
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(isProminent ? 0.08 : 0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(isProminent ? 0.22 : 0.1), radius: isProminent ? 18 : 10, x: 0, y: isProminent ? 10 : 6)
        }
        .buttonStyle(.plain)
    }

    private var backgroundStyle: AnyShapeStyle {
        if isProminent {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color.white.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }
}

struct PrimaryActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                PrimaryActionButton(title: "Sign Up") {}
                PrimaryActionButton(title: "Log In", isProminent: false) {}
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
