import SwiftUI
import Foundation
import UIKit

// MARK: - Image data

enum AvatarImageProcessor {
    static func preparedAvatarData(_ data: Data, maxDimension: CGFloat = 640) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else {
            return image.jpegData(compressionQuality: 0.82) ?? data
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.82) ?? data
    }
}

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
        case .present: return .green
        case .absent:  return .red
        case .late:    return .orange
        case .excused: return .blue
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
        case .paid:    return .green
        case .unpaid:  return .red
        case .partial: return .orange
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
                    AppTheme.ocean
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
