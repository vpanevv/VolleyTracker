import PhotosUI
import SwiftUI

struct EditProfileView: View {
    let coach: Coach
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var club = ""
    @State private var role: CoachRole = .headCoach
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 26) {
                        avatarEditor

                        VStack(alignment: .leading, spacing: 14) {
                            CourtSectionLabel("Profile details", subtitle: "Shown throughout your workspace.")
                            CourtTextField(
                                label: "Full name",
                                placeholder: "Your name",
                                icon: "person.fill",
                                text: $name,
                                isRequired: true,
                                contentType: .name,
                                capitalization: .words
                            )
                            CourtTextField(
                                label: "Club or organization",
                                placeholder: "Optional",
                                icon: "building.2.fill",
                                text: $club,
                                contentType: .organizationName,
                                capitalization: .words,
                                submitLabel: .done
                            )
                        }

                        roleSelector

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.coral)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Coach Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.deepBlue)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Saving…" : "Save Profile")
                    }
                }
                .buttonStyle(CourtPrimaryButtonStyle())
                .disabled(name.trimmed.isEmpty || isSaving)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
            .onAppear {
                name = coach.name
                club = coach.club
                role = coach.role
                photoData = coach.photoData
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var avatarEditor: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.heroGradient)
                        .frame(width: 124, height: 124)
                        .blur(radius: 20)
                        .opacity(0.24)
                    PlayerAvatarView(photoData: photoData, name: name, size: 104)
                        .overlay(Circle().strokeBorder(AppTheme.heroGradient, lineWidth: 3))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.navy)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.sun, in: Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }
                }
                Text("Change profile photo")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.deepBlue)
            }
        }
        .buttonStyle(.plain)
    }

    private var roleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            CourtSectionLabel("Role")
            HStack(spacing: 9) {
                ForEach(CoachRole.allCases, id: \.self) { option in
                    Button {
                        role = option
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: option.icon)
                                .font(.title3.weight(.bold))
                            Text(shortName(for: option))
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(role == option ? AppTheme.navy : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(
                            role == option ? AnyShapeStyle(AppTheme.energyGradient)
                                           : AnyShapeStyle(.regularMaterial),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(role == option ? Color.clear : AppTheme.ocean.opacity(0.16), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.rawValue)
                }
            }
        }
    }

    private func shortName(for role: CoachRole) -> String {
        switch role {
        case .headCoach: "Head"
        case .assistantCoach: "Assistant"
        case .teamManager: "Manager"
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await CloudDataService.shared.upsertProfile(
                ownerID: coach.remoteID,
                name: name.trimmed,
                club: club.trimmed,
                role: role,
                photoData: photoData
            )
            coach.name = name.trimmed
            coach.club = club.trimmed
            coach.role = role
            coach.photoData = photoData
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
