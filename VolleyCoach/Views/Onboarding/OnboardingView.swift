import SwiftUI
import SwiftData
import PhotosUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var step = 0
    @State private var name = ""
    @State private var club = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i <= step ? Color.volleyballOrange : Color.secondary.opacity(0.25))
                            .frame(width: i == step ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: step)
                    }
                }
                .padding(.top, 20)

                TabView(selection: $step) {
                    step0.tag(0)
                    step1.tag(1)
                    step2.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    // MARK: Step 0 — Name & Club

    private var step0: some View {
        scrollPage {
            heroIcon("sportscourt.fill")
            titleBlock(
                title: "Welcome to VolleyCoach",
                subtitle: "Manage teams, track attendance, and handle payments — all offline, all in one place."
            )
            VStack(spacing: 12) {
                styledField("Your full name", text: $name, contentType: .name)
                styledField("Club / Organization (optional)", text: $club)
            }
            Spacer()
            nextButton("Continue", enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty) {
                withAnimation { step = 1 }
            }
        }
    }

    // MARK: Step 1 — Contact

    private var step1: some View {
        scrollPage {
            heroIcon("envelope.circle.fill")
            titleBlock(title: "Contact Info", subtitle: "Optional — helps you stay organized.")
            VStack(spacing: 12) {
                styledField("Email address", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                    .autocapitalization(.none)
                styledField("Phone number", text: $phone, contentType: .telephoneNumber, keyboard: .phonePad)
            }
            Spacer()
            backNextRow(back: { withAnimation { step = 0 } },
                        next: { withAnimation { step = 2 } })
        }
    }

    // MARK: Step 2 — Photo

    private var step2: some View {
        scrollPage {
            PhotosPicker(selection: $photoItem, matching: .images) {
                photoPicker
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            titleBlock(
                title: "Looking good, \(name.components(separatedBy: " ").first ?? name)!",
                subtitle: "Add a profile photo — optional but nice."
            )
            Spacer()
            backNextRow(
                back: { withAnimation { step = 1 } },
                nextLabel: "Get Started",
                next: finish
            )
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func scrollPage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 32)
                content()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func heroIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 64))
            .foregroundStyle(Color.volleyballOrange)
    }

    private func titleBlock(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func styledField(
        _ placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .padding()
            .background(.quaternary, in: .rect(cornerRadius: 12))
    }

    private func nextButton(_ label: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(enabled ? Color.volleyballOrange : Color.secondary, in: .rect(cornerRadius: 16))
        }
        .disabled(!enabled)
    }

    private func backNextRow(
        back: @escaping () -> Void,
        nextLabel: String = "Continue",
        next: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Button(action: back) {
                Text("Back")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .foregroundStyle(Color.volleyballOrange)
                    .padding()
                    .background(Color.volleyballOrange.opacity(0.12), in: .rect(cornerRadius: 16))
            }
            nextButton(nextLabel, action: next)
        }
    }

    private var photoPicker: some View {
        Group {
            if let data = photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(.circle)
                    .overlay(Circle().stroke(Color.volleyballOrange, lineWidth: 3))
            } else {
                ZStack {
                    Circle()
                        .fill(Color.volleyballOrange.opacity(0.15))
                        .frame(width: 100, height: 100)
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(Color.volleyballOrange)
                        Text("Add Photo")
                            .font(.caption)
                            .foregroundStyle(Color.volleyballOrange)
                    }
                }
            }
        }
    }

    private func finish() {
        let coach = Coach(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            club: club.trimmingCharacters(in: .whitespaces)
        )
        coach.photoData = photoData
        modelContext.insert(coach)
    }
}
