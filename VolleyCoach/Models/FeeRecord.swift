import SwiftData
import Foundation

enum FeeStatus: String, Codable, CaseIterable {
    case unpaid  = "Unpaid"
    case paid    = "Paid"
    case partial = "Partial"

    var colorHex: String {
        switch self {
        case .paid:    return "#34C759"
        case .unpaid:  return "#FF3B30"
        case .partial: return "#FF9500"
        }
    }

    var sfSymbol: String {
        switch self {
        case .paid:    return "checkmark.circle.fill"
        case .unpaid:  return "xmark.circle.fill"
        case .partial: return "minus.circle.fill"
        }
    }

    /// Cycles: unpaid → paid → partial → unpaid
    var next: FeeStatus {
        switch self {
        case .unpaid:  return .paid
        case .paid:    return .partial
        case .partial: return .unpaid
        }
    }
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
        self.month = month
        self.year = year
        self.statusRaw = status.rawValue
        self.notes = ""
        self.createdAt = Date()
    }
}
