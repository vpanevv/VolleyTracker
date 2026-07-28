import SwiftUI

struct MainTabView: View {
    let coach: Coach

    var body: some View {
        TabView {
            DashboardHomeView(coach: coach)
                .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2.fill") }

            GroupsListView(coach: coach)
                .tabItem { Label("Teams", systemImage: "person.3.fill") }

            CalendarTabView(coach: coach)
                .tabItem { Label("Schedule", systemImage: "calendar.badge.clock") }

            SettingsView(coach: coach)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(AppTheme.ocean)
    }
}
