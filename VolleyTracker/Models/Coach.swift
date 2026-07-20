import SwiftData
import Foundation

enum CoachRole: String, CaseIterable, Codable {
    case headCoach = "Head Coach"
    case assistantCoach = "Assistant Coach"
    case teamManager = "Team Manager"

    var icon: String {
        switch self {
        case .headCoach: "sportscourt.fill"
        case .assistantCoach: "person.2.fill"
        case .teamManager: "clipboard.fill"
        }
    }
}

@Model
final class Coach {
    var remoteID: UUID
    var name: String
    var club: String
    var role: CoachRole
    var photoData: Data?

    @Relationship(deleteRule: .cascade) var groups: [TeamGroup] = []

    init(remoteID: UUID = UUID(), name: String, club: String = "", role: CoachRole = .headCoach) {
        self.remoteID = remoteID
        self.name = name
        self.club = club
        self.role = role
    }

    var initials: String {
        let parts = name.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }
}
