import SwiftUI

struct MainTabView: View {
    let coach: Coach

    var body: some View {
        TabView {
            GroupsListView(coach: coach)
                .tabItem { Label("Home", systemImage: "house.fill") }

            CalendarTabView(coach: coach)
                .tabItem { Label("Schedule", systemImage: "calendar.badge.clock") }

            SettingsView(coach: coach)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(AppTheme.ocean)
    }
}
