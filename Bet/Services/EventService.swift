import Foundation

protocol EventProviding {
    func fetchTodayEvents() async throws -> [Event]
}

final class EventService: EventProviding {
    private let cacheKey = "events.today.cache"
    private let calendar = Calendar.current

    func fetchTodayEvents() async throws -> [Event] {
        if let cached = loadCachedEvents(), isToday(events: cached) {
            return cached
        }

        let generated = generateMockEvents()
        saveCachedEvents(generated)
        return generated
    }

    private func isToday(events: [Event]) -> Bool {
        guard let first = events.first else { return false }
        return calendar.isDateInToday(first.startDate)
    }

    private func loadCachedEvents() -> [Event]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([Event].self, from: data)
    }

    private func saveCachedEvents(_ events: [Event]) {
        let data = try? JSONEncoder().encode(events)
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func generateMockEvents() -> [Event] {
        let now = Date()
        let sports: [SportType] = [.football, .basketball, .tennis, .hockey]
        var events: [Event] = []
        for index in 0..<12 {
            let minutes = (index * 5) + 5 // deterministic spacing to avoid shifting
            let start = calendar.date(byAdding: .minute, value: minutes, to: now) ?? now.addingTimeInterval(300)
            let sport = sports[index % sports.count]
            let (home, away) = realTeams(for: sport, index: index)
            events.append(Event(id: UUID().uuidString, sport: sport, homeTeam: home, awayTeam: away, startDate: start, outcome: nil))
        }
        return events.sorted(by: { $0.startDate < $1.startDate })
    }

    private func realTeams(for sport: SportType, index: Int) -> (String, String) {
        switch sport {
        case .football:
            let teams = ["Real Madrid", "Barcelona", "Liverpool", "Manchester City", "PSG", "Bayern"]
            return (teams[index % teams.count], teams[(index + 1) % teams.count])
        case .basketball:
            let teams = ["Lakers", "Celtics", "Warriors", "Bulls", "Heat", "Nets"]
            return (teams[index % teams.count], teams[(index + 1) % teams.count])
        case .tennis:
            let players = ["Djokovic", "Alcaraz", "Sinner", "Medvedev", "Zverev", "Nadal"]
            return (players[index % players.count], players[(index + 1) % players.count])
        case .hockey:
            let teams = ["Maple Leafs", "Canadiens", "Rangers", "Bruins", "Red Wings", "Blackhawks"]
            return (teams[index % teams.count], teams[(index + 1) % teams.count])
        case .baseball:
            let teams = ["Yankees", "Red Sox", "Dodgers", "Cubs", "Giants", "Mets"]
            return (teams[index % teams.count], teams[(index + 1) % teams.count])
        }
    }
}


