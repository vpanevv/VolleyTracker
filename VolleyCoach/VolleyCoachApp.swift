import SwiftUI
import SwiftData

@main
struct VolleyCoachApp: App {

    let container: ModelContainer = {
        let schema = Schema([
            Coach.self,
            TeamGroup.self,
            Player.self,
            AttendanceSession.self,
            AttendanceRecord.self,
            FeeRecord.self
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("ModelContainer creation failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Query private var coaches: [Coach]

    var body: some View {
        if coaches.isEmpty {
            OnboardingView()
        } else {
            MainTabView(coach: coaches[0])
        }
    }
}

struct MainTabView: View {
    let coach: Coach

    var body: some View {
        TabView {
            GroupsListView(coach: coach)
                .tabItem { Label("Groups", systemImage: "person.3.fill") }

            SettingsView(coach: coach)
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.volleyballOrange)
    }
}
