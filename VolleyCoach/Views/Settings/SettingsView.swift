import SwiftUI
import PhotosUI

struct SettingsView: View {
    let coach: Coach
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var name = ""
    @State private var club = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        if isEditing {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                PlayerPhotoView(photoData: photoData, name: name, size: 64)
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundStyle(Color.volleyballOrange)
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
                        } else {
                            PlayerPhotoView(photoData: coach.photoData, name: coach.name, size: 64)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Your name", text: $name)
                                    .font(.title3.bold())
                                TextField("Club / Organization", text: $club)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(coach.name).font(.title3.bold())
                                if !coach.club.isEmpty {
                                    Text(coach.club).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                if isEditing {
                    Section("Contact") {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        TextField("Phone", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                } else {
                    Section("Contact") {
                        if !coach.email.isEmpty { LabeledContent("Email", value: coach.email) }
                        if !coach.phone.isEmpty { LabeledContent("Phone", value: coach.phone) }
                        if coach.email.isEmpty && coach.phone.isEmpty {
                            Text("No contact info added").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Statistics") {
                    let totalPlayers = coach.groups.reduce(0) { $0 + $1.players.count }
                    let totalSessions = coach.groups.reduce(0) { $0 + $1.attendanceSessions.count }

                    LabeledContent("Groups", value: "\(coach.groups.count)")
                    LabeledContent("Total Players", value: "\(totalPlayers)")
                    LabeledContent("Attendance Sessions", value: "\(totalSessions)")
                }

                Section("App") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { isEditing = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { saveProfile() }
                            .fontWeight(.semibold)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { startEditing() }
                    }
                }
            }
        }
    }

    private func startEditing() {
        name      = coach.name
        club      = coach.club
        email     = coach.email
        phone     = coach.phone
        photoData = coach.photoData
        isEditing = true
    }

    private func saveProfile() {
        coach.name      = name.trimmingCharacters(in: .whitespaces)
        coach.club      = club.trimmingCharacters(in: .whitespaces)
        coach.email     = email.trimmingCharacters(in: .whitespaces)
        coach.phone     = phone.trimmingCharacters(in: .whitespaces)
        coach.photoData = photoData
        isEditing = false
    }
}
