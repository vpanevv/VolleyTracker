import SwiftUI
import SwiftData

@main
struct VolleyTrackerApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    let container: ModelContainer = {
        let schema = Schema([
            Coach.self,
            TeamGroup.self,
            Player.self,
            TrainingSession.self,
            AttendanceRecord.self,
            FeeRecord.self
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Schema changed (e.g. property renamed) — wipe the local store and start fresh.
            // All data is local-only so this is safe during development.
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeBase = appSupport.appendingPathComponent("default.store")
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(
                    at: URL(fileURLWithPath: storeBase.path + suffix))
            }
            do {
                return try ModelContainer(for: schema)
            } catch let retryError {
                fatalError("ModelContainer creation failed after store reset: \(retryError)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                LoggedInRootView()
            } else {
                WelcomeView()
            }
        }
        .modelContainer(container)
    }
}

// MARK: - Logged-in root

struct LoggedInRootView: View {
    @Query private var coaches: [Coach]
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        if let coach = coaches.first {
            MainTabView(coach: coach)
        } else {
            // isLoggedIn=true but no coach in store — reset and show welcome
            WelcomeView()
                .onAppear { isLoggedIn = false }
        }
    }
}
