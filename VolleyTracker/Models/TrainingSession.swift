import SwiftData
import Foundation

@Model
final class TrainingSession {
    var remoteID: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var notes: String
    var createdAt: Date

    // Back-reference to parent group (inverse of TeamGroup.trainingSessions)
    var group: TeamGroup?

    @Relationship(deleteRule: .cascade) var attendanceRecords: [AttendanceRecord] = []

    init(remoteID: UUID = UUID(), date: Date, startTime: Date, endTime: Date, notes: String = "") {
        self.remoteID = remoteID
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

    var scheduledStart: Date {
        combinedDate(using: startTime)
    }

    var scheduledEnd: Date {
        combinedDate(using: endTime)
    }

    var timeRange: String {
        let fmt = DateFormatter()
        fmt.locale = AppLanguage.selected.locale
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return "\(fmt.string(from: startTime))–\(fmt.string(from: endTime))"
    }

    private func combinedDate(using time: Date) -> Date {
        let calendar = Calendar.current
        let dateParts = calendar.dateComponents([.year, .month, .day], from: date)
        let timeParts = calendar.dateComponents([.hour, .minute, .second], from: time)
        var components = DateComponents()
        components.year = dateParts.year
        components.month = dateParts.month
        components.day = dateParts.day
        components.hour = timeParts.hour
        components.minute = timeParts.minute
        components.second = timeParts.second
        return calendar.date(from: components) ?? date
    }
}
