import SwiftUI

struct MainTabView: View {
    let coach: Coach

    var body: some View {
        TabView {
            GroupsListView(coach: coach)
                .tabItem { Label("Groups", systemImage: "person.3.fill") }

            CalendarTabView(coach: coach)
                .tabItem { Label("Calendar", systemImage: "calendar") }

            SettingsView(coach: coach)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.blue)
    }
}
