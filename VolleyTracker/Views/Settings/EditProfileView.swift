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
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            PlayerAvatarView(photoData: photoData, name: name, size: 88)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                        .background(Color(.systemBackground), in: .circle)
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

                Section("Profile") {
                    TextField("Your Name", text: $name)
                        .textContentType(.name)
                    TextField("Club / Organization", text: $club)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
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
