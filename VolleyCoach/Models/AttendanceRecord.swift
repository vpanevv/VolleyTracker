import SwiftData
import Foundation

enum AttendanceStatus: String, Codable, CaseIterable {
    case present = "Present"
    case absent  = "Absent"
    case late    = "Late"
    case excused = "Excused"

    var sfSymbol: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .absent:  return "xmark.circle.fill"
        case .late:    return "clock.fill"
        case .excused: return "person.badge.clock.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .present: return "#34C759"
        case .absent:  return "#FF3B30"
        case .late:    return "#FF9500"
        case .excused: return "#5AC8FA"
        }
    }
}

@Model
final class AttendanceRecord {
    var player: Player?
    var playerName: String   // snapshot so display survives player deletion
    var statusRaw: String

    var status: AttendanceStatus {
        get { AttendanceStatus(rawValue: statusRaw) ?? .absent }
        set { statusRaw = newValue.rawValue }
    }

    init(player: Player, status: AttendanceStatus = .present) {
        self.player = player
        self.playerName = player.fullName
        self.statusRaw = status.rawValue
    }
}
