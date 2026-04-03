import SwiftData
import Foundation

enum AttendanceStatus: String, Codable, CaseIterable {
    case present = "Present"
    case absent  = "Absent"
    case late    = "Late"
    case excused = "Excused"
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
