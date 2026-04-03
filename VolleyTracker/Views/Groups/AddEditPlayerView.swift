import SwiftUI
import SwiftData
import PhotosUI

struct AddEditPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let group: TeamGroup
    var player: Player?

    @State private var fullName = ""
    @State private var jerseyText = ""
    @State private var position: PlayerPosition = .unknown
    @State private var dob: Date = Calendar.current.date(byAdding: .year, value: -16, to: Date()) ?? Date()
    @State private var hasDOB = false
    @State private var parentName = ""
    @State private var parentPhone = ""
    @State private var notes = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    private var isEditing: Bool { player != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Photo
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            PlayerAvatarView(photoData: photoData, name: fullName, size: 88)
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

                Section("Player Info") {
                    TextField("Full name", text: $fullName)
                        .textContentType(.name)

                    HStack {
                        Text("Jersey #")
                        Spacer()
                        TextField("Optional", text: $jerseyText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    Picker("Position", selection: $position) {
                        ForEach(PlayerPosition.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }

                    Toggle("Date of Birth", isOn: $hasDOB.animation())

                    if hasDOB {
                        DatePicker("", selection: $dob, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                }

                Section("Parent / Guardian") {
                    TextField("Name (optional)", text: $parentName)
                        .textContentType(.name)
                    TextField("Phone (optional)", text: $parentPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "Edit Player" : "New Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(fullName.trimmed.isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        guard let p = player else { return }
        fullName    = p.fullName
        jerseyText  = p.jerseyNumber.map(String.init) ?? ""
        position    = p.position
        parentName  = p.parentName
        parentPhone = p.parentPhone
        notes       = p.notes
        photoData   = p.photoData
        if let d = p.dateOfBirth { hasDOB = true; dob = d }
    }

    private func save() {
        let jersey = Int(jerseyText)

        if let p = player {
            p.fullName     = fullName.trimmed
            p.jerseyNumber = jersey
            p.position     = position
            p.dateOfBirth  = hasDOB ? dob : nil
            p.parentName   = parentName.trimmed
            p.parentPhone  = parentPhone.trimmed
            p.notes        = notes.trimmed
            p.photoData    = photoData
        } else {
            let p = Player(fullName: fullName.trimmed, jerseyNumber: jersey, position: position)
            p.dateOfBirth  = hasDOB ? dob : nil
            p.parentName   = parentName.trimmed
            p.parentPhone  = parentPhone.trimmed
            p.notes        = notes.trimmed
            p.photoData    = photoData
            modelContext.insert(p)
            group.players.append(p)
        }
        dismiss()
    }
}
