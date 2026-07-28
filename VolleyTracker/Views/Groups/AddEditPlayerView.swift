import PhotosUI
import SwiftData
import SwiftUI

struct AddEditPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let group: TeamGroup
    var player: Player?

    @State private var fullName = ""
    @State private var jerseyText = ""
    @State private var position: PlayerPosition = .unknown
    @State private var dob = Calendar.current.date(byAdding: .year, value: -16, to: Date()) ?? Date()
    @State private var hasDOB = false
    @State private var parentName = ""
    @State private var parentPhone = ""
    @State private var notes = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var draftRemoteID = UUID()

    private var isEditing: Bool { player != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 26) {
                        avatarEditor

                        formSection("Player details", subtitle: "The essentials you use court-side.") {
                            CourtTextField(
                                label: "Full name",
                                placeholder: "Player name",
                                icon: "person.fill",
                                text: $fullName,
                                isRequired: true,
                                contentType: .name,
                                capitalization: .words
                            )
                            CourtTextField(
                                label: "Jersey number",
                                placeholder: "Optional",
                                icon: "number",
                                text: $jerseyText,
                                keyboardType: .numberPad,
                                capitalization: .never
                            )
                            selectionRow
                        }

                        formSection("Personal", subtitle: "Useful for age groups and birthdays.") {
                            toggleRow(
                                icon: "birthday.cake.fill",
                                title: "Add date of birth",
                                subtitle: hasDOB ? dob.formatted(date: .abbreviated, time: .omitted) : "Optional",
                                isOn: $hasDOB
                            )
                            if hasDOB {
                                DatePicker(
                                    "Date of birth",
                                    selection: $dob,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(AppTheme.ocean)
                                .padding(10)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            }
                        }

                        formSection("Parent or guardian", subtitle: "Optional contact details.") {
                            CourtTextField(
                                label: "Contact name",
                                placeholder: "Optional",
                                icon: "person.2.fill",
                                text: $parentName,
                                contentType: .name,
                                capitalization: .words
                            )
                            CourtTextField(
                                label: "Phone number",
                                placeholder: "Optional",
                                icon: "phone.fill",
                                text: $parentPhone,
                                contentType: .telephoneNumber,
                                keyboardType: .phonePad,
                                capitalization: .never,
                                submitLabel: .done
                            )
                        }

                        CourtTextEditor(
                            label: "Coach notes",
                            placeholder: "Add development goals, restrictions, or useful context…",
                            text: $notes
                        )

                        if let errorMessage {
                            Label(errorMessage, systemImage: "icloud.slash.fill")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.coral)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(
                Text(LocalizedStringKey(isEditing ? "Edit Player" : "New Player"))
            )
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
                        Text(isSaving ? "Saving…" : (isEditing ? "Save Player" : "Add Player"))
                    }
                }
                .buttonStyle(CourtPrimaryButtonStyle())
                .disabled(fullName.trimmed.isEmpty || isSaving)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
            .onAppear(perform: loadIfEditing)
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = AvatarImageProcessor.preparedAvatarData(data)
                    }
                }
            }
        }
    }

    private var avatarEditor: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.heroGradient)
                        .frame(width: 116, height: 116)
                        .blur(radius: 18)
                        .opacity(0.22)
                    PlayerAvatarView(photoData: photoData, name: fullName, size: 96)
                        .overlay(Circle().strokeBorder(AppTheme.heroGradient, lineWidth: 3))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.navy)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.sun, in: Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }
                }
                Text(photoData == nil ? "Add player photo" : "Change player photo")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.deepBlue)
            }
        }
        .buttonStyle(.plain)
    }

    private var selectionRow: some View {
        HStack(spacing: 12) {
            CourtIconBadge(icon: "figure.volleyball", size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text("Position")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(LocalizedStringKey(position.rawValue))
                    .font(.body.weight(.semibold))
            }
            Spacer()
            Picker("Position", selection: $position) {
                ForEach(PlayerPosition.allCases, id: \.self) { option in
                    Text(LocalizedStringKey(option.rawValue)).tag(option)
                }
            }
            .labelsHidden()
            .tint(AppTheme.ocean)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(AppTheme.ocean.opacity(0.16), lineWidth: 1)
        )
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            CourtIconBadge(icon: icon, tint: AppTheme.sun, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title)).font(.body.weight(.semibold))
                Text(LocalizedStringKey(subtitle)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn.animation())
                .labelsHidden()
                .tint(AppTheme.ocean)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(AppTheme.ocean.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func formSection<Content: View>(
        _ title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            CourtSectionLabel(title, subtitle: subtitle)
            content()
        }
    }

    private func loadIfEditing() {
        guard let player else { return }
        fullName = player.fullName
        jerseyText = player.jerseyNumber.map(String.init) ?? ""
        position = player.position
        parentName = player.parentName
        parentPhone = player.parentPhone
        notes = player.notes
        photoData = player.photoData
        if let date = player.dateOfBirth {
            hasDOB = true
            dob = date
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        let jersey = Int(jerseyText)
        let savedPlayer: Player
        if let player {
            player.fullName = fullName.trimmed
            player.jerseyNumber = jersey
            player.position = position
            player.dateOfBirth = hasDOB ? dob : nil
            player.parentName = parentName.trimmed
            player.parentPhone = parentPhone.trimmed
            player.notes = notes.trimmed
            player.photoData = photoData
            savedPlayer = player
        } else {
            let player = Player(
                remoteID: draftRemoteID,
                fullName: fullName.trimmed,
                jerseyNumber: jersey,
                position: position
            )
            player.dateOfBirth = hasDOB ? dob : nil
            player.parentName = parentName.trimmed
            player.parentPhone = parentPhone.trimmed
            player.notes = notes.trimmed
            player.photoData = photoData
            modelContext.insert(player)
            group.players.append(player)
            savedPlayer = player
        }

        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()

        Task { try? await CloudDataService.shared.upsertPlayer(savedPlayer, groupID: group.remoteID) }
        isSaving = false
    }

    private func apply(_ draft: Player, to player: Player) {
        player.fullName = draft.fullName
        player.jerseyNumber = draft.jerseyNumber
        player.position = draft.position
        player.dateOfBirth = draft.dateOfBirth
        player.parentName = draft.parentName
        player.parentPhone = draft.parentPhone
        player.notes = draft.notes
        player.photoData = draft.photoData
    }
}
