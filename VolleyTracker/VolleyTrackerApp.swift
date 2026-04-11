import SwiftUI
import SwiftData

@main
struct VolleyTrackerApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    let container: ModelContainer = {
        let schema = Schema([
            Coach.self,
            TeamGroup.self,
            Player.self,
            TrainingSession.self,
            AttendanceRecord.self,
            FeeRecord.self
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Schema changed (e.g. property renamed) — wipe the local store and start fresh.
            // All data is local-only so this is safe during development.
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeBase = appSupport.appendingPathComponent("default.store")
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(
                    at: URL(fileURLWithPath: storeBase.path + suffix))
            }
            do {
                return try ModelContainer(for: schema)
            } catch let retryError {
                fatalError("ModelContainer creation failed after store reset: \(retryError)")
            }
        }
    }()

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--seed-demo") {
            DebugSeed.seedIfRequested(context: container.mainContext)
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                LoggedInRootView()
            } else {
                WelcomeView()
            }
        }
        .modelContainer(container)
    }
}

// MARK: - Debug seed

#if DEBUG
enum DebugSeed {
    static func seedIfRequested(context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("--seed-demo") else { return }

        // Wipe existing
        try? context.delete(model: Coach.self)
        try? context.delete(model: TeamGroup.self)
        try? context.delete(model: Player.self)
        try? context.delete(model: TrainingSession.self)
        try? context.delete(model: AttendanceRecord.self)
        try? context.delete(model: FeeRecord.self)

        let coach = Coach(name: "Vladimir Panev", club: "CSKA Sofia")
        context.insert(coach)

        let groupsData: [(String, String, String, String, Double, [String])] = [
            ("U18 Women", "U18", "#FF2D55", "👧", 45,
             ["Maria Ivanova","Elena Petrova","Viktoria Dimitrova","Sofia Nikolova","Ralitsa Todorova","Deni Georgieva"]),
            ("U16 Men",   "U16", "#007AFF", "👦", 40,
             ["Alex Stoyanov","Martin Iliev","Kaloyan Petrov","Ivaylo Dimitrov","Nikola Vasilev"]),
            ("U14 Girls", "U14", "#AF52DE", "👧", 35,
             ["Anna Ivanova","Lilia Marinova","Kristina Popova","Gabriela Todorova"])
        ]

        for (name, age, hex, emoji, fee, players) in groupsData {
            let g = TeamGroup(name: name, ageCategory: age, colorHex: hex, emoji: emoji, monthlyFee: fee)
            g.trainingDays = [1, 3, 5]
            context.insert(g)
            coach.groups.append(g)

            for (i, playerName) in players.enumerated() {
                let p = Player(fullName: playerName, jerseyNumber: i + 1,
                               position: [.setter, .outsideHitter, .libero, .middleBlocker, .oppositeHitter][i % 5])
                context.insert(p)
                g.players.append(p)
                // Mark some as paid for current month
                if i < players.count - 1 {
                    let now = Date()
                    let m = Calendar.current.component(.month, from: now)
                    let y = Calendar.current.component(.year, from: now)
                    let fr = FeeRecord(month: m, year: y, status: .paid)
                    fr.amount = fee
                    fr.paymentDate = now
                    context.insert(fr)
                    p.feeRecords.append(fr)
                }
            }
        }

        try? context.save()
    }
}
#endif

// MARK: - Logged-in root

struct LoggedInRootView: View {
    @Query private var coaches: [Coach]
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        if let coach = coaches.first {
            MainTabView(coach: coach)
        } else {
            // isLoggedIn=true but no coach in store — reset and show welcome
            WelcomeView()
                .onAppear { isLoggedIn = false }
        }
    }
}
