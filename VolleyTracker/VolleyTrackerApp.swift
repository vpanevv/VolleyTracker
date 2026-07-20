import SwiftData
import SwiftUI
import PhotosUI

@main
struct VolleyTrackerApp: App {
    @StateObject private var authStore = AuthStore()

    private let container: ModelContainer = {
        let schema = Schema([
            Coach.self,
            TeamGroup.self,
            Player.self,
            TrainingSession.self,
            AttendanceRecord.self,
            FeeRecord.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to create the in-memory app cache: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CloudAppRoot()
                .environmentObject(authStore)
        }
        .modelContainer(container)
    }
}

struct CloudAppRoot: View {
    @EnvironmentObject private var authStore: AuthStore
    @Environment(\.modelContext) private var modelContext
    @Query private var coaches: [Coach]

    @State private var loadedUserID: UUID?
    @State private var isLoadingCloud = false
    @State private var loadError: String?

    var body: some View {
        Group {
            if authStore.isLoading || isLoadingCloud {
                CloudLoadingView()
            } else if let session = authStore.session {
                if let coach = coaches.first(where: { $0.remoteID == session.user.id }) {
                    MainTabView(coach: coach)
                } else if let loadError {
                    CloudLoadErrorView(
                        message: loadError,
                        onRetry: { Task { await load(userID: session.user.id, force: true) } },
                        onLogOut: { Task { await authStore.signOut() } }
                    )
                } else {
                    CreateCloudProfileView(userID: session.user.id) {
                        await load(userID: session.user.id, force: true)
                    }
                }
            } else {
                WelcomeView()
            }
        }
        .task(id: authStore.session?.user.id) {
            guard let userID = authStore.session?.user.id else {
                loadedUserID = nil
                return
            }
            await load(userID: userID)
        }
    }

    private func load(userID: UUID, force: Bool = false) async {
        guard force || loadedUserID != userID else { return }
        isLoadingCloud = true
        loadError = nil
        do {
            try await CloudDataService.shared.loadAll(ownerID: userID, into: modelContext)
            loadedUserID = userID
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingCloud = false
    }
}

private struct CreateCloudProfileView: View {
    let userID: UUID
    let onCreated: () async -> Void

    @State private var name = ""
    @State private var club = ""
    @State private var role: CoachRole = .headCoach
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var step = 0
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canContinue: Bool { step == 1 || !name.trimmed.isEmpty }
    private var firstName: String {
        name.trimmed.split(separator: " ").first.map(String.init) ?? "Coach"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        onboardingHeader

                        Group {
                            if step == 0 {
                                identityStep
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                            removal: .move(edge: .leading).combined(with: .opacity)))
                            } else {
                                teamStep
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                            removal: .move(edge: .leading).combined(with: .opacity)))
                            }
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.coral)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                        }

                        Spacer(minLength: 110)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if step == 1 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { step = 0 }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.deepBlue)
                    }

                    Button {
                        if step == 0 {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { step = 1 }
                        } else {
                            Task { await createProfile() }
                        }
                    } label: {
                        HStack(spacing: 9) {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text(step == 0 ? "Continue" : "Enter VolleyTracker")
                                Image(systemName: step == 0 ? "arrow.right" : "figure.volleyball")
                            }
                        }
                    }
                    .buttonStyle(CourtPrimaryButtonStyle())
                    .disabled(!canContinue || isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
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

    private var onboardingHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 9) {
                    CourtIconBadge(icon: "figure.volleyball", tint: AppTheme.sun, size: 38)
                    Text("VOLLEYTRACKER")
                        .font(.caption.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.deepBlue)
                }
                Spacer()
                Text("STEP \(step + 1) OF 2")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.ocean.opacity(0.12))
                    Capsule()
                        .fill(AppTheme.heroGradient)
                        .frame(width: proxy.size.width * (step == 0 ? 0.5 : 1))
                }
            }
            .frame(height: 6)

            VStack(alignment: .leading, spacing: 7) {
                Text(step == 0 ? "Build your coach profile" : "Set up your workspace")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(step == 0
                     ? "Add the identity your teams will recognize."
                     : "Choose your role and tell us where you coach.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var identityStep: some View {
        VStack(spacing: 24) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                VStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.heroGradient)
                            .frame(width: 118, height: 118)
                            .blur(radius: 18)
                            .opacity(0.24)
                        PlayerAvatarView(photoData: photoData, name: name, size: 100)
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
                    Text(photoData == nil ? "Add profile photo" : "Change profile photo")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.deepBlue)
                }
            }
            .buttonStyle(.plain)

            CourtTextField(
                label: "Full name",
                placeholder: "e.g. Alex Morgan",
                icon: "person.fill",
                text: $name,
                isRequired: true,
                helper: "This appears on your coach profile.",
                contentType: .name,
                capitalization: .words,
                submitLabel: .done
            )
        }
    }

    private var teamStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                CourtSectionLabel("Your role", subtitle: "You can update this later.")
                ForEach(CoachRole.allCases, id: \.self) { option in
                    Button {
                        role = option
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        HStack(spacing: 13) {
                            CourtIconBadge(icon: option.icon,
                                           tint: role == option ? AppTheme.sun : AppTheme.ocean,
                                           size: 42)
                            Text(option.rawValue)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: role == option ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(role == option ? AppTheme.success : Color.secondary.opacity(0.45))
                        }
                        .padding(14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .strokeBorder(role == option ? AnyShapeStyle(AppTheme.heroGradient)
                                              : AnyShapeStyle(AppTheme.ocean.opacity(0.15)),
                                              lineWidth: role == option ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            CourtTextField(
                label: "Club or organization",
                placeholder: "Optional",
                icon: "building.2.fill",
                text: $club,
                helper: "Leave this blank if you coach independently.",
                contentType: .organizationName,
                capitalization: .words,
                submitLabel: .done
            )

            HStack(spacing: 12) {
                CourtIconBadge(icon: "checkmark.shield.fill", tint: AppTheme.success, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready for the first serve, \(firstName)")
                        .font(.subheadline.weight(.semibold))
                    Text("Your profile and team data sync securely across devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(AppTheme.success.opacity(0.09), in: RoundedRectangle(cornerRadius: 17))
        }
    }

    private func createProfile() async {
        isSaving = true
        errorMessage = nil
        do {
            try await CloudDataService.shared.upsertProfile(
                ownerID: userID,
                name: name.trimmed,
                club: club.trimmed,
                role: role,
                photoData: photoData
            )
            await onCreated()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private struct CloudLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.ocean.opacity(0.14), lineWidth: 8)
                        .frame(width: 84, height: 84)
                    Circle()
                        .trim(from: 0, to: 0.68)
                        .stroke(AppTheme.heroGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 84, height: 84)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    Image(systemName: "figure.volleyball")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.deepBlue)
                }
                Text("Preparing your court…")
                    .font(.headline)
                Text("Syncing teams, sessions and fees")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

private struct CloudLoadErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onLogOut: () -> Void

    var body: some View {
        ZStack {
            AuroraBackground()
            GlassCard {
                VStack(spacing: 18) {
                    CourtIconBadge(icon: "icloud.slash.fill", tint: AppTheme.coral, size: 58)
                    Text("We couldn’t sync your data")
                        .font(.title3.weight(.bold))
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again", action: onRetry)
                        .buttonStyle(CourtPrimaryButtonStyle())
                    Button("Log Out", role: .destructive, action: onLogOut)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(22)
            }
            .padding(24)
        }
    }
}
