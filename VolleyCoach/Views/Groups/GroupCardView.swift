import SwiftUI

struct GroupCardView: View {
    let group: TeamGroup

    private var color: Color { Color(hex: group.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Coloured header
            ZStack(alignment: .topLeading) {
                color
                Image(systemName: group.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.18))
                    .offset(x: 28, y: 8)
                Image(systemName: group.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .frame(height: 80)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.headline)
                    .lineLimit(1)

                if !group.ageCategory.isEmpty {
                    Text(group.ageCategory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text("\(group.players.count) player\(group.players.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                if !group.trainingDays.isEmpty {
                    Text(group.trainingDaysDisplay)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(12)
        }
        .background(.background)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}
