import SwiftData
import Foundation

@Model
final class Coach {
    var name: String
    var club: String
    var photoData: Data?

    @Relationship(deleteRule: .cascade) var groups: [TeamGroup] = []

    init(name: String, club: String = "") {
        self.name = name
        self.club = club
    }

    var initials: String {
        let parts = name.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }
}
