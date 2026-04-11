import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let coach: Coach
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var club = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        // Avatar hero
                        VStack(spacing: 14) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.heroGradient)
                                        .frame(width: 108, height: 108)
                                        .blur(radius: 10)
                                        .opacity(0.55)
                                    PlayerAvatarView(photoData: photoData, name: name, size: 96)
                                        .overlay(
                                            Circle().strokeBorder(
                                                AppTheme.heroGradient,
                                                lineWidth: 3
                                            )
                                        )
                                        .overlay(alignment: .bottomTrailing) {
                                            ZStack {
                                                Circle()
                                                    .fill(AppTheme.heroGradient)
                                                    .frame(width: 30, height: 30)
                                                Image(systemName: "pencil")
                                                    .font(.footnote.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                            .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.4),
                                                    radius: 8, x: 0, y: 4)
                                        }
                                }
                            }
                            .onChange(of: photoItem) { _, item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self) {
                                        photoData = data
                                    }
                                }
                            }

                            Text("Tap to change photo")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        // Profile fields
                        VStack(alignment: .leading, spacing: 10) {
                            ThemedSectionLabel("PROFILE")
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ThemedTextField(icon: "person.fill",
                                                placeholder: "Your name",
                                                text: $name,
                                                contentType: .name)
                                Divider().padding(.leading, 54)
                                ThemedTextField(icon: "building.2.fill",
                                                placeholder: "Club / Organization",
                                                text: $club,
                                                contentType: nil)
                            }
                            .background(.ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(AppTheme.softGradient.opacity(0.55), lineWidth: 1)
                            )
                            .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.10),
                                    radius: 18, x: 0, y: 10)
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(.secondaryLabel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        Text("Save")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(AppTheme.heroGradient, in: Capsule())
                            .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.35),
                                    radius: 10, x: 0, y: 5)
                            .opacity(name.trimmed.isEmpty ? 0.5 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmed.isEmpty)
                }
            }
            .onAppear {
                name      = coach.name
                club      = coach.club
                photoData = coach.photoData
            }
        }
    }

    private func save() {
        coach.name      = name.trimmed
        coach.club      = club.trimmed
        coach.photoData = photoData
        dismiss()
    }
}

// MARK: - Themed helpers (shared with AddTrainingView)

struct ThemedSectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.heroGradient)
    }
}

struct ThemedTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.heroGradient.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .heroGradientForeground()
            }
            TextField(placeholder, text: $text)
                .textContentType(contentType)
                .font(.body)
                .foregroundStyle(Color(.label))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
