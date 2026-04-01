import SwiftData
import Foundation

@Model
final class Coach {
    var name: String
    var email: String
    var phone: String
    var club: String
    var photoData: Data?

    @Relationship(deleteRule: .cascade) var groups: [TeamGroup] = []

    init(name: String, email: String = "", phone: String = "", club: String = "") {
        self.name = name
        self.email = email
        self.phone = phone
        self.club = club
    }

    var initials: String {
        let parts = name.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }
}
