import SwiftData
import Foundation

@Model
final class AttendanceSession {
    var date: Date
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var records: [AttendanceRecord] = []

    init(date: Date = Date()) {
        self.date = date
        self.createdAt = Date()
    }

    var presentCount: Int  { records.filter { $0.status == .present }.count }
    var absentCount: Int   { records.filter { $0.status == .absent  }.count }
    var lateCount: Int     { records.filter { $0.status == .late    }.count }
    var excusedCount: Int  { records.filter { $0.status == .excused }.count }
}
