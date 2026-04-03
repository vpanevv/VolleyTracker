import SwiftData
import Foundation

// Named TeamGroup to avoid collision with SwiftUI's Group view.
@Model
final class TeamGroup {
    var name: String
    var ageCategory: String
    var colorHex: String
    var emoji: String
    var trainingDays: [Int]     // 0 = Sunday … 6 = Saturday
    var trainingTime: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var players: [Player] = []
    @Relationship(deleteRule: .cascade) var trainingSessions: [TrainingSession] = []

    init(
        name: String,
        ageCategory: String = "",
        colorHex: String = "#007AFF",
        emoji: String = "🏐"
    ) {
        self.name         = name
        self.ageCategory  = ageCategory
        self.colorHex     = colorHex
        self.emoji        = emoji
        self.trainingDays = []
        self.createdAt    = Date()
    }

    var trainingDaysDisplay: String {
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        let sorted = trainingDays.sorted()
        guard !sorted.isEmpty else { return "No schedule set" }
        return sorted.compactMap { $0 < names.count ? names[$0] : nil }.joined(separator: ", ")
    }

    func attendancePercentage(for player: Player) -> Double {
        let sessionsWithRecords = trainingSessions.filter { $0.attendanceTaken }
        guard !sessionsWithRecords.isEmpty else { return 0 }
        let presentCount = sessionsWithRecords.reduce(0) { count, session in
            let record = session.attendanceRecords.first {
                $0.player?.persistentModelID == player.persistentModelID
            }
            return count + (record?.status == .present ? 1 : 0)
        }
        return Double(presentCount) / Double(sessionsWithRecords.count) * 100
    }
}
