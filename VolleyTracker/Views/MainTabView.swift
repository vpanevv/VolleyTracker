import SwiftUI

struct MainTabView: View {
    let coach: Coach

    init(coach: Coach) {
        self.coach = coach

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.courtBlue)

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            GroupsListView(coach: coach)
                .tabItem { Label("Groups", systemImage: "person.3.fill") }

            CalendarTabView(coach: coach)
                .tabItem { Label("Calendar", systemImage: "calendar") }

            SettingsView(coach: coach)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.white)
    }
}
