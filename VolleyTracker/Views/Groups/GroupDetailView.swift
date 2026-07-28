import SwiftUI

enum GroupTab: String, CaseIterable {
    case players    = "Players"
    case attendance = "Attendance"
    case fees       = "Fees"

    var icon: String {
        switch self {
        case .players: "person.2.fill"
        case .attendance: "checkmark.circle.fill"
        case .fees: "banknote.fill"
        }
    }
}

struct GroupDetailView: View {
    let coach: Coach
    let group: TeamGroup
    @State private var selectedTab: GroupTab = {
        ProcessInfo.processInfo.arguments.contains("--open-fees") ? .fees : .players
    }()
    @State private var searchText = ""
    @State private var showingEditGroup = false
    @State private var showingAddPlayer = false
    @State private var showingAddTraining = false
    private var teamTint: Color { Color(teamHex: group.colorHex) }

    var body: some View {
        ZStack {
            CourtWorkspaceBackground()

            VStack(spacing: 0) {
                ThemedSegmentedPicker(selection: $selectedTab, tint: teamTint)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if selectedTab == .players {
                    GroupPlayerSearchField(text: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer().frame(height: 12)

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
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { primaryAction() } label: {
                    Image(systemName: primaryActionIcon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(teamTint)
                        .frame(width: 38, height: 38)
                        .background(.regularMaterial, in: Circle())
                }
                .accessibilityLabel(primaryActionLabel)

                Menu {
                    Button { showingAddPlayer = true } label: {
                        Label("Add Player", systemImage: "person.badge.plus")
                    }
                    Button { showingAddTraining = true } label: {
                        Label("Add Training", systemImage: "calendar.badge.plus")
                    }
                    Button { showingEditGroup = true } label: {
                        Label("Edit Team", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .heroGradientForeground()
                }
                .accessibilityLabel("Team actions")
            }
        }
        .sheet(isPresented: $showingEditGroup) {
            AddEditGroupView(coach: coach, group: group)
        }
        .sheet(isPresented: $showingAddPlayer) {
            AddEditPlayerView(group: group)
        }
        .sheet(isPresented: $showingAddTraining) {
            AddTrainingView(groups: [group], preselectedGroup: group)
        }
        .animation(.easeOut(duration: 0.2), value: selectedTab)
    }

    private var primaryActionIcon: String {
        switch selectedTab {
        case .players: "person.badge.plus"
        case .attendance: "calendar.badge.plus"
        case .fees: "banknote.fill"
        }
    }

    private var primaryActionLabel: String {
        switch selectedTab {
        case .players: "Add player"
        case .attendance: "Add training"
        case .fees: "Edit monthly fee"
        }
    }

    private func primaryAction() {
        switch selectedTab {
        case .players:
            showingAddPlayer = true
        case .attendance:
            showingAddTraining = true
        case .fees:
            showingEditGroup = true
        }
    }
}

private struct GroupPlayerSearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isFocused ? AppTheme.ocean : Color.secondary)
            TextField("Search players", text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isFocused ? AnyShapeStyle(AppTheme.heroGradient)
                              : AnyShapeStyle(AppTheme.ocean.opacity(0.16)),
                              lineWidth: isFocused ? 2 : 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.07), radius: 10, y: 5)
    }
}

// MARK: - Themed segmented picker

struct ThemedSegmentedPicker: View {
    @Binding var selection: GroupTab
    let tint: Color
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
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.caption.weight(.bold))
                        Text(LocalizedStringKey(tab.rawValue))
                            .font(.footnote.weight(.bold))
                    }
                        .foregroundStyle(isSelected ? AnyShapeStyle(Color.white)
                                                    : AnyShapeStyle(Color.secondary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [tint, tint.opacity(0.72), AppTheme.ocean],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "pill", in: ns)
                                    .shadow(color: tint.opacity(0.22),
                                            radius: 8, x: 0, y: 4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.08), radius: 12, y: 6)
    }
}
