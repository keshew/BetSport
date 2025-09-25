import Foundation

final class PredictionService {
    static let shared = PredictionService()
    private init() {}

    private let predictionsKey = "predictions.storage"
    private let pointsKey = "profile.points"
    private let eventsKey = "events.today.cache"

    func loadPredictions() -> [Prediction] {
        guard let data = UserDefaults.standard.data(forKey: predictionsKey) else { return [] }
        let decoded = (try? JSONDecoder().decode([Prediction].self, from: data)) ?? []
        return decoded
    }

    func savePredictions(_ items: [Prediction]) {
        let data = (try? JSONEncoder().encode(items))
        UserDefaults.standard.set(data, forKey: predictionsKey)
        NotificationCenter.default.post(name: .predictionsUpdated, object: nil)
    }

    func addPrediction(eventId: String, userId: String, outcome: PredictionOutcome) {
        var items = loadPredictions()
        // replace existing prediction for the same event/user
        items.removeAll { $0.eventId == eventId && $0.userId == userId }
        let prediction = Prediction(id: UUID().uuidString, eventId: eventId, userId: userId, createdAt: Date(), outcome: outcome, isCorrect: nil)
        items.append(prediction)
        savePredictions(items)
    }

    func awardPoints(_ points: Int) {
        let current = UserDefaults.standard.integer(forKey: pointsKey)
        UserDefaults.standard.set(current + points, forKey: pointsKey)
        NotificationCenter.default.post(name: .predictionsUpdated, object: nil)
    }

    func currentPoints() -> Int {
        UserDefaults.standard.integer(forKey: pointsKey)
    }

    // Resolve outcomes when events start and award points
    func resolveEventsAndAwardPoints() {
        guard var events = loadCachedEvents() else { return }
        var predictions = loadPredictions()
        let userId = AuthService.shared.currentUser?.id ?? "guest"

        var awarded = 0
        for index in events.indices {
            if events[index].hasStarted && events[index].outcome == nil {
                // randomly decide outcome for mock purposes
                let decided = PredictionOutcome.allCases.randomElement() ?? .draw
                events[index].outcome = decided
                // check prediction
                if let p = predictions.first(where: { $0.eventId == events[index].id && $0.userId == userId }) {
                    let correct = (p.outcome == decided)
                    if let idx = predictions.firstIndex(where: { $0.id == p.id }) {
                        predictions[idx].isCorrect = correct
                    }
                    if correct { awarded += 10 }
                }
            }
        }

        if awarded > 0 { awardPoints(awarded) }
        savePredictions(predictions)
        saveCachedEvents(events)
        NotificationCenter.default.post(name: .eventsResolved, object: nil)
    }

    private func loadCachedEvents() -> [Event]? {
        guard let data = UserDefaults.standard.data(forKey: eventsKey) else { return nil }
        return try? JSONDecoder().decode([Event].self, from: data)
    }

    private func saveCachedEvents(_ events: [Event]) {
        let data = try? JSONEncoder().encode(events)
        UserDefaults.standard.set(data, forKey: eventsKey)
    }
}

extension Notification.Name {
    static let predictionsUpdated = Notification.Name("predictionsUpdated")
    static let eventsResolved = Notification.Name("eventsResolved")
}


