import SwiftData
import Foundation

enum FeeStatus: String, Codable, CaseIterable {
    case unpaid  = "Unpaid"
    case paid    = "Paid"
    case partial = "Partial"
}

@Model
final class FeeRecord {
    var month: Int   // 1–12
    var year: Int
    var statusRaw: String
    var amount: Double?
    var paymentDate: Date?
    var notes: String
    var createdAt: Date

    var status: FeeStatus {
        get { FeeStatus(rawValue: statusRaw) ?? .unpaid }
        set { statusRaw = newValue.rawValue }
    }

    static let monthNames = ["Jan","Feb","Mar","Apr","May","Jun",
                             "Jul","Aug","Sep","Oct","Nov","Dec"]

    var monthName: String {
        guard month >= 1, month <= 12 else { return "?" }
        return FeeRecord.monthNames[month - 1]
    }

    init(month: Int, year: Int, status: FeeStatus = .unpaid) {
        self.month     = month
        self.year      = year
        self.statusRaw = status.rawValue
        self.notes     = ""
        self.createdAt = Date()
    }
}
