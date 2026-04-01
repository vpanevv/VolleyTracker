import SwiftData
import Foundation

@Model
final class TeamGroup {
    var name: String
    var ageCategory: String
    var colorHex: String
    var icon: String
    var trainingDays: [Int]   // 0 = Sunday … 6 = Saturday
    var trainingTime: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var players: [Player] = []
    @Relationship(deleteRule: .cascade) var attendanceSessions: [AttendanceSession] = []

    init(
        name: String,
        ageCategory: String = "",
        colorHex: String = "#FF6B35",
        icon: String = "sportscourt.fill"
    ) {
        self.name = name
        self.ageCategory = ageCategory
        self.colorHex = colorHex
        self.icon = icon
        self.trainingDays = []
        self.createdAt = Date()
    }

    var trainingDaysDisplay: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = trainingDays.sorted()
        guard !sorted.isEmpty else { return "No schedule set" }
        return sorted.compactMap { $0 < names.count ? names[$0] : nil }.joined(separator: ", ")
    }

    func attendancePercentage(for player: Player) -> Double {
        guard !attendanceSessions.isEmpty else { return 0 }
        let presentCount = attendanceSessions.reduce(0) { count, session in
            let record = session.records.first { $0.player?.persistentModelID == player.persistentModelID }
            return count + (record?.status == .present ? 1 : 0)
        }
        return Double(presentCount) / Double(attendanceSessions.count) * 100
    }
}
