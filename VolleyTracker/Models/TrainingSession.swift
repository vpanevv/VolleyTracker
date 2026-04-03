import SwiftData
import Foundation

@Model
final class TrainingSession {
    var date: Date
    var startTime: Date
    var endTime: Date
    var notes: String
    var createdAt: Date

    // Back-reference to parent group (inverse of TeamGroup.trainingSessions)
    var group: TeamGroup?

    @Relationship(deleteRule: .cascade) var attendanceRecords: [AttendanceRecord] = []

    init(date: Date, startTime: Date, endTime: Date, notes: String = "") {
        self.date      = date
        self.startTime = startTime
        self.endTime   = endTime
        self.notes     = notes
        self.createdAt = Date()
    }

    var presentCount: Int { attendanceRecords.filter { $0.status == .present }.count }
    var absentCount:  Int { attendanceRecords.filter { $0.status == .absent  }.count }
    var lateCount:    Int { attendanceRecords.filter { $0.status == .late    }.count }
    var excusedCount: Int { attendanceRecords.filter { $0.status == .excused }.count }

    var attendanceTaken: Bool { !attendanceRecords.isEmpty }

    var timeRange: String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return "\(fmt.string(from: startTime))–\(fmt.string(from: endTime))"
    }
}
