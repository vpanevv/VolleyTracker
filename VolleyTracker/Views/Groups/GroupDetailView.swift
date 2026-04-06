import SwiftUI

enum GroupTab: String, CaseIterable {
    case players    = "Players"
    case attendance = "Attendance"
    case fees       = "Fees"
}

struct GroupDetailView: View {
    let group: TeamGroup
    @State private var selectedTab: GroupTab = .players
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(GroupTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            switch selectedTab {
            case .players:
                PlayerListView(group: group, searchText: searchText)
            case .attendance:
                AttendanceView(group: group)
            case .fees:
                FeeOverviewView(group: group)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search players")
    }
}
