import Foundation
import SwiftData
import Supabase
import UIKit

@MainActor
final class CloudDataService {
    static let shared = CloudDataService()
    private let client = SupabaseConfig.client

    func loadAll(ownerID: UUID, into context: ModelContext) async throws {
        async let profileRequest: [CoachProfileRow] = client.from("coach_profiles").select().execute().value
        async let groupRequest: [TeamGroupRow] = client.from("team_groups").select().execute().value
        async let playerRequest: [PlayerRow] = client.from("players").select().execute().value
        async let sessionRequest: [TrainingSessionRow] = client.from("training_sessions").select().execute().value
        async let attendanceRequest: [AttendanceRow] = client.from("attendance_records").select().execute().value
        async let feeRequest: [FeeRow] = client.from("fee_records").select().execute().value

        let (profiles, groups, players, sessions, attendance, fees) = try await (
            profileRequest, groupRequest, playerRequest, sessionRequest, attendanceRequest, feeRequest
        )

        let profile = profiles.first(where: { $0.id == ownerID })
        var coachPhoto: Data?
        if let path = profile?.avatarPath {
            coachPhoto = try? await client.storage.from("avatars").download(path: path)
        }
        var playerPhotos: [UUID: Data] = [:]
        for player in players {
            if let path = player.avatarPath,
               let data = try? await client.storage.from("avatars").download(path: path) {
                playerPhotos[player.id] = data
            }
        }

        await MainActor.run {
            try? context.delete(model: Coach.self)
            try? context.delete(model: TeamGroup.self)
            try? context.delete(model: Player.self)
            try? context.delete(model: TrainingSession.self)
            try? context.delete(model: AttendanceRecord.self)
            try? context.delete(model: FeeRecord.self)

            guard let profile else {
                try? context.save()
                return
            }

            let coach = Coach(
                remoteID: profile.id,
                name: profile.fullName,
                club: profile.club,
                role: CoachRole(rawValue: profile.role) ?? .headCoach
            )
            coach.photoData = coachPhoto
            context.insert(coach)

            var groupModels: [UUID: TeamGroup] = [:]
            for row in groups {
                let group = TeamGroup(
                    remoteID: row.id,
                    name: row.name,
                    ageCategory: row.ageCategory,
                    colorHex: row.colorHex,
                    emoji: row.emoji,
                    monthlyFee: row.monthlyFee
                )
                group.trainingDays = row.trainingDays
                group.trainingTime = row.trainingTime.flatMap(CloudDate.time)
                context.insert(group)
                coach.groups.append(group)
                groupModels[row.id] = group
            }

            var playerModels: [UUID: Player] = [:]
            for row in players {
                guard let group = groupModels[row.groupID] else { continue }
                let player = Player(
                    remoteID: row.id,
                    fullName: row.fullName,
                    jerseyNumber: row.jerseyNumber,
                    position: PlayerPosition(rawValue: row.position) ?? .unknown
                )
                player.dateOfBirth = row.dateOfBirth.flatMap(CloudDate.day)
                player.parentName = row.parentName
                player.parentPhone = row.parentPhone
                player.notes = row.notes
                player.photoData = playerPhotos[row.id]
                context.insert(player)
                group.players.append(player)
                playerModels[row.id] = player
            }

            var sessionModels: [UUID: TrainingSession] = [:]
            for row in sessions {
                guard let group = groupModels[row.groupID],
                      let day = CloudDate.day(row.sessionDate),
                      let start = CloudDate.time(row.startTime),
                      let end = CloudDate.time(row.endTime) else { continue }
                let session = TrainingSession(
                    remoteID: row.id,
                    date: day,
                    startTime: start,
                    endTime: end,
                    notes: row.notes
                )
                context.insert(session)
                group.trainingSessions.append(session)
                sessionModels[row.id] = session
            }

            for row in fees {
                guard let player = playerModels[row.playerID] else { continue }
                let fee = FeeRecord(
                    remoteID: row.id,
                    month: row.month,
                    year: row.year,
                    status: FeeStatus(rawValue: row.status) ?? .unpaid
                )
                fee.amount = row.amount
                fee.paymentDate = row.paymentDate.flatMap(CloudDate.timestamp)
                fee.notes = row.notes
                context.insert(fee)
                player.feeRecords.append(fee)
            }

            for row in attendance {
                guard let session = sessionModels[row.sessionID],
                      let playerID = row.playerID,
                      let player = playerModels[playerID] else { continue }
                let record = AttendanceRecord(
                    remoteID: row.id,
                    player: player,
                    status: AttendanceStatus(rawValue: row.status) ?? .absent
                )
                record.playerName = row.playerName
                context.insert(record)
                session.attendanceRecords.append(record)
            }

            try? context.save()
        }
    }

    func upsertProfile(
        ownerID: UUID,
        name: String,
        club: String,
        role: CoachRole = .headCoach,
        photoData: Data? = nil
    ) async throws {
        let ownerFolder = ownerID.uuidString.lowercased()
        let avatarPath = try await uploadPhoto(photoData, path: "\(ownerFolder)/coach.jpg")
        try await client.from("coach_profiles").upsert(
            CoachProfileRow(
                id: ownerID,
                fullName: name,
                club: club,
                role: role.rawValue,
                avatarPath: avatarPath
            )
        ).execute()
    }

    func upsertGroup(_ group: TeamGroup) async throws {
        let ownerID = try await client.auth.session.user.id
        try await client.from("team_groups").upsert(TeamGroupRow(group, ownerID: ownerID)).execute()
    }

    func upsertPlayer(_ player: Player, groupID: UUID) async throws {
        let ownerID = try await client.auth.session.user.id
        let ownerFolder = ownerID.uuidString.lowercased()
        let avatarPath = try await uploadPhoto(
            player.photoData,
            path: "\(ownerFolder)/players/\(player.remoteID.uuidString.lowercased()).jpg"
        )
        try await client.from("players").upsert(
            PlayerRow(player, groupID: groupID, ownerID: ownerID, avatarPath: avatarPath)
        ).execute()
    }

    func upsertSession(_ session: TrainingSession, groupID: UUID) async throws {
        let ownerID = try await client.auth.session.user.id
        try await client.from("training_sessions").upsert(TrainingSessionRow(session, groupID: groupID, ownerID: ownerID)).execute()
    }

    func replaceAttendance(for session: TrainingSession) async throws {
        let ownerID = try await client.auth.session.user.id
        try await client.from("attendance_records").delete().eq("session_id", value: session.remoteID).execute()
        let rows = session.attendanceRecords.compactMap { AttendanceRow($0, sessionID: session.remoteID, ownerID: ownerID) }
        if !rows.isEmpty {
            try await client.from("attendance_records").insert(rows).execute()
        }
    }

    func upsertFee(_ fee: FeeRecord, playerID: UUID) async throws {
        let ownerID = try await client.auth.session.user.id
        try await client.from("fee_records").upsert(FeeRow(fee, playerID: playerID, ownerID: ownerID)).execute()
    }

    func delete(table: String, id: UUID) async throws {
        try await client.from(table).delete().eq("id", value: id).execute()
    }

    private func uploadPhoto(_ data: Data?, path: String) async throws -> String? {
        guard let data, let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.82) else {
            return nil
        }
        try await client.storage.from("avatars").upload(
            path,
            data: jpeg,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
        return path
    }
}

private struct CoachProfileRow: Codable, Sendable {
    let id: UUID
    let fullName: String
    let club: String
    let role: String
    let avatarPath: String?

    enum CodingKeys: String, CodingKey {
        case id, club, role
        case fullName = "full_name", avatarPath = "avatar_path"
    }
}

private struct TeamGroupRow: Codable, Sendable {
    let id: UUID
    let ownerID: UUID?
    let name: String
    let ageCategory: String
    let colorHex: String
    let emoji: String
    let trainingDays: [Int]
    let trainingTime: String?
    let monthlyFee: Double

    enum CodingKeys: String, CodingKey {
        case id, name, emoji
        case ownerID = "owner_id", ageCategory = "age_category", colorHex = "color_hex"
        case trainingDays = "training_days", trainingTime = "training_time", monthlyFee = "monthly_fee"
    }

    init(_ group: TeamGroup, ownerID: UUID) {
        id = group.remoteID; self.ownerID = ownerID; name = group.name
        ageCategory = group.ageCategory; colorHex = group.colorHex; emoji = group.emoji
        trainingDays = group.trainingDays; trainingTime = group.trainingTime.map(CloudDate.timeString)
        monthlyFee = group.monthlyFee
    }
}

private struct PlayerRow: Codable, Sendable {
    let id: UUID
    let ownerID: UUID?
    let groupID: UUID
    let fullName: String
    let dateOfBirth: String?
    let jerseyNumber: Int?
    let position: String
    let parentName: String
    let parentPhone: String
    let notes: String
    let avatarPath: String?

    enum CodingKeys: String, CodingKey {
        case id, position, notes
        case ownerID = "owner_id", groupID = "group_id", fullName = "full_name"
        case dateOfBirth = "date_of_birth", jerseyNumber = "jersey_number"
        case parentName = "parent_name", parentPhone = "parent_phone", avatarPath = "avatar_path"
    }

    init(_ player: Player, groupID: UUID, ownerID: UUID, avatarPath: String?) {
        id = player.remoteID; self.ownerID = ownerID; self.groupID = groupID
        fullName = player.fullName; dateOfBirth = player.dateOfBirth.map(CloudDate.dayString)
        jerseyNumber = player.jerseyNumber; position = player.position.rawValue
        parentName = player.parentName; parentPhone = player.parentPhone; notes = player.notes
        self.avatarPath = avatarPath
    }
}

private struct TrainingSessionRow: Codable, Sendable {
    let id: UUID
    let ownerID: UUID?
    let groupID: UUID
    let sessionDate: String
    let startTime: String
    let endTime: String
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id, notes
        case ownerID = "owner_id", groupID = "group_id", sessionDate = "session_date"
        case startTime = "start_time", endTime = "end_time"
    }

    init(_ session: TrainingSession, groupID: UUID, ownerID: UUID) {
        id = session.remoteID; self.ownerID = ownerID; self.groupID = groupID
        sessionDate = CloudDate.dayString(session.date); startTime = CloudDate.timeString(session.startTime)
        endTime = CloudDate.timeString(session.endTime); notes = session.notes
    }
}

private struct AttendanceRow: Codable, Sendable {
    let id: UUID
    let ownerID: UUID?
    let sessionID: UUID
    let playerID: UUID?
    let playerName: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case ownerID = "owner_id", sessionID = "session_id", playerID = "player_id", playerName = "player_name"
    }

    init?(_ record: AttendanceRecord, sessionID: UUID, ownerID: UUID) {
        guard let player = record.player else { return nil }
        id = record.remoteID; self.ownerID = ownerID; self.sessionID = sessionID
        playerID = player.remoteID; playerName = record.playerName; status = record.status.rawValue
    }
}

private struct FeeRow: Codable, Sendable {
    let id: UUID
    let ownerID: UUID?
    let playerID: UUID
    let month: Int
    let year: Int
    let status: String
    let amount: Double?
    let paymentDate: String?
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id, month, year, status, amount, notes
        case ownerID = "owner_id", playerID = "player_id", paymentDate = "payment_date"
    }

    init(_ fee: FeeRecord, playerID: UUID, ownerID: UUID) {
        id = fee.remoteID; self.ownerID = ownerID; self.playerID = playerID
        month = fee.month; year = fee.year; status = fee.status.rawValue; amount = fee.amount
        paymentDate = fee.paymentDate.map(CloudDate.timestampString); notes = fee.notes
    }
}

private enum CloudDate {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian); formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"; return formatter
    }()
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian); formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss"; return formatter
    }()
    static let iso = ISO8601DateFormatter()

    static func day(_ string: String) -> Date? { dayFormatter.date(from: string) }
    static func time(_ string: String) -> Date? { timeFormatter.date(from: String(string.prefix(8))) }
    static func timestamp(_ string: String) -> Date? { iso.date(from: string) }
    static func dayString(_ date: Date) -> String { dayFormatter.string(from: date) }
    static func timeString(_ date: Date) -> String { timeFormatter.string(from: date) }
    static func timestampString(_ date: Date) -> String { iso.string(from: date) }
}
