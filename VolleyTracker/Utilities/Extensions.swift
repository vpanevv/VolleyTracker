import SwiftUI
import Foundation

// MARK: - String

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}

// MARK: - Character

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.value > 0x238C
    }
}

// MARK: - Date

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Calendar

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

// MARK: - AttendanceStatus UI

extension AttendanceStatus {
    var sfSymbol: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .absent:  return "xmark.circle.fill"
        case .late:    return "clock.fill"
        case .excused: return "person.badge.clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .present: return AppTheme.successGreen
        case .absent:  return AppTheme.dangerRed
        case .late:    return AppTheme.warningAmber
        case .excused: return AppTheme.activeBlue
        }
    }
}

// MARK: - FeeStatus UI

extension FeeStatus {
    var sfSymbol: String {
        switch self {
        case .paid:    return "checkmark.circle.fill"
        case .unpaid:  return "xmark.circle.fill"
        case .partial: return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .paid:    return AppTheme.successGreen
        case .unpaid:  return AppTheme.dangerRed
        case .partial: return AppTheme.warningAmber
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

// MARK: - PlayerPosition UI

extension PlayerPosition {
    var sfSymbol: String {
        switch self {
        case .setter:              return "arrow.up.circle.fill"
        case .libero:              return "shield.lefthalf.filled"
        case .outsideHitter:       return "bolt.fill"
        case .oppositeHitter:      return "bolt.circle.fill"
        case .middleBlocker:       return "rectangle.fill"
        case .defensiveSpecialist: return "shield"
        case .unknown:             return "person.fill"
        }
    }
}

// MARK: - PlayerAvatarView

struct PlayerAvatarView: View {
    let photoData: Data?
    let name: String
    let size: CGFloat
    var color: Color = AppTheme.courtBlueLite

    private var initials: String {
        let parts = name.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }

    var body: some View {
        Group {
            if let data = photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    color
                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }
}
