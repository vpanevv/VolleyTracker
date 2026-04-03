import SwiftData
import Foundation

enum PlayerPosition: String, Codable, CaseIterable {
    case setter              = "Setter"
    case libero              = "Libero"
    case outsideHitter       = "Outside Hitter"
    case oppositeHitter      = "Opposite Hitter"
    case middleBlocker       = "Middle Blocker"
    case defensiveSpecialist = "Defensive Specialist"
    case unknown             = "Unknown"
}

@Model
final class Player {
    var fullName: String
    var dateOfBirth: Date?
    var photoData: Data?
    var jerseyNumber: Int?
    var positionRaw: String
    var parentName: String
    var parentPhone: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var feeRecords: [FeeRecord] = []

    var position: PlayerPosition {
        get { PlayerPosition(rawValue: positionRaw) ?? .unknown }
        set { positionRaw = newValue.rawValue }
    }

    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }

    init(fullName: String, jerseyNumber: Int? = nil, position: PlayerPosition = .unknown) {
        self.fullName    = fullName
        self.jerseyNumber = jerseyNumber
        self.positionRaw = position.rawValue
        self.parentName  = ""
        self.parentPhone = ""
        self.notes       = ""
        self.createdAt   = Date()
    }
}
