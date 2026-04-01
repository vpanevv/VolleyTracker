import SwiftUI

enum GroupTab: String, CaseIterable {
    case players    = "Players"
    case attendance = "Attendance"
    case fees       = "Fees"

    var sfSymbol: String {
        switch self {
        case .players:    return "person.fill"
        case .attendance: return "calendar.badge.checkmark"
        case .fees:       return "creditcard.fill"
        }
    }
}

struct GroupDetailView: View {
    let group: TeamGroup
    @State private var selectedTab: GroupTab = .players

    private var groupColor: Color { Color(hex: group.colorHex) }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                ForEach(GroupTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.sfSymbol).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Each child view manages its own toolbar items via .toolbar modifiers,
            // which propagate up to the parent NavigationStack.
            switch selectedTab {
            case .players:
                PlayerListView(group: group)
            case .attendance:
                AttendanceHistoryView(group: group)
            case .fees:
                FeeOverviewView(group: group)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .tint(groupColor)
        .toolbar {
            // Show group stats in trailing if there are players
            ToolbarItem(placement: .topBarTrailing) {
                if group.players.isEmpty { EmptyView() } else {
                    Label("\(group.players.count)", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(groupColor)
                }
            }
        }
    }
}
