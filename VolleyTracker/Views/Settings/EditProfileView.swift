import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let coach: Coach
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var club = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    private func themedHeader(_ text: String) -> some View {
        Text(text)
            .foregroundColor(AppTheme.courtBlueLite)
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            PlayerAvatarView(photoData: photoData, name: name, size: 88)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.activeBlue)
                                        .background(AppTheme.cardSurface, in: .circle)
                                }
                        }
                        .onChange(of: photoItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    photoData = data
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    TextField("Your Name", text: $name)
                        .textContentType(.name)
                    TextField("Club / Organization", text: $club)
                } header: { themedHeader("Profile") }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.skyBlue)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.courtBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
