import SwiftUI

enum GroupTab: String, CaseIterable {
    case players    = "Players"
    case attendance = "Attendance"
    case fees       = "Fees"
}

struct GroupDetailView: View {
    let group: TeamGroup
    @State private var selectedTab: GroupTab = {
        ProcessInfo.processInfo.arguments.contains("--open-fees") ? .fees : .players
    }()
    @State private var searchText = ""

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                ThemedSegmentedPicker(selection: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                switch selectedTab {
                case .players:
                    PlayerListView(group: group, searchText: searchText)
                case .attendance:
                    AttendanceView(group: group)
                case .fees:
                    FeeOverviewView(group: group)
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search players")
    }
}

// MARK: - Themed segmented picker

struct ThemedSegmentedPicker: View {
    @Binding var selection: GroupTab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(GroupTab.allCases, id: \.self) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = tab
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(tab.rawValue)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(isSelected ? AnyShapeStyle(Color.white)
                                                    : AnyShapeStyle(Color(.label)))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(AppTheme.heroGradient)
                                    .matchedGeometryEffect(id: "pill", in: ns)
                                    .shadow(color: Color(red: 0.24, green: 0.40, blue: 1.00).opacity(0.35),
                                            radius: 10, x: 0, y: 5)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(AppTheme.softGradient.opacity(0.5), lineWidth: 1)
        )
    }
}
