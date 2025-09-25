import Foundation

enum SportType: String, Codable, CaseIterable, Identifiable {
    case football
    case basketball
    case tennis
    case hockey
    case baseball

    var id: String { rawValue }
}

struct Event: Identifiable, Codable, Hashable {
    let id: String
    let sport: SportType
    let homeTeam: String
    let awayTeam: String
    let startDate: Date
    var outcome: PredictionOutcome?

    var hasStarted: Bool { Date() >= startDate }
    var isLocked: Bool { hasStarted }
}

enum PredictionOutcome: String, Codable, CaseIterable, Identifiable {
    case homeWin
    case draw
    case awayWin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeWin: return "Home"
        case .draw: return "Draw"
        case .awayWin: return "Away"
        }
    }
}

struct Prediction: Identifiable, Codable, Hashable {
    let id: String
    let eventId: String
    let userId: String
    let createdAt: Date
    let outcome: PredictionOutcome
    var isCorrect: Bool?
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: String
    var displayName: String
    var totalPoints: Int
}

struct Challenge: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let target: Int
    var progress: Int
    let rewardPoints: Int
    var isCompleted: Bool
    var validDate: Date
}

struct PeriodStats: Codable, Hashable {
    var total: Int
    var correct: Int

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var losses: Int { max(0, total - correct) }
}

struct UserStats: Codable, Hashable {
    var day: PeriodStats
    var week: PeriodStats
    var month: PeriodStats
}


