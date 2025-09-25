import SwiftUI

final class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var predictions: [String: PredictionOutcome] = [:]
    @Published var isLoading: Bool = false
    @Published var now: Date = Date()

    private let eventProvider: EventProviding
    private var timer: Timer?

    init(eventProvider: EventProviding = EventService()) {
        self.eventProvider = eventProvider
        hydratePredictions()
    }

    @MainActor
    func loadIfNeeded() async {
        if !events.isEmpty { return }
        await load()
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await eventProvider.fetchTodayEvents()
            self.events = fetched
            startTicking()
        } catch {
            self.events = []
        }
    }

    func makePrediction(for event: Event, outcome: PredictionOutcome) {
        guard !event.isLocked else { return }
        let userId = AuthService.shared.currentUser?.id ?? "guest"
        predictions[event.id] = outcome
        PredictionService.shared.addPrediction(eventId: event.id, userId: userId, outcome: outcome)
    }

    private func hydratePredictions() {
        let userId = AuthService.shared.currentUser?.id ?? "guest"
        let stored = PredictionService.shared.loadPredictions().filter { $0.userId == userId }
        var dict: [String: PredictionOutcome] = [:]
        for p in stored { dict[p.eventId] = p.outcome }
        self.predictions = dict
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.now = Date()
            // When an event starts, resolve outcomes and refresh points
            PredictionService.shared.resolveEventsAndAwardPoints()
            // Refresh events from cache without re-generating
            if let updated = self.loadCachedEvents() {
                self.events = updated
            }
        }
    }

    private func loadCachedEvents() -> [Event]? {
        let key = "events.today.cache"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([Event].self, from: data)
    }
}

struct EventsFeedView: View {
    @StateObject private var viewModel = EventsViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.events) { event in
                        EventRow(event: event, now: viewModel.now, selected: viewModel.predictions[event.id]) { outcome in
                            viewModel.makePrediction(for: event, outcome: outcome)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Events")
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct EventRow: View {
    let event: Event
    let now: Date
    let selected: PredictionOutcome?
    let onSelect: (PredictionOutcome) -> Void

    var remaining: TimeInterval { max(0, event.startDate.timeIntervalSince(now)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.sport.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(event.isLocked ? "Locked" : formatTime(remaining))
                    .font(.caption)
                    .foregroundColor(event.isLocked ? .red : .blue)
                    .monospacedDigit()
            }
            HStack {
                Text(event.homeTeam)
                    .font(.headline)
                Text("vs")
                    .foregroundColor(.secondary)
                Text(event.awayTeam)
                    .font(.headline)
            }
            HStack(spacing: 8) {
                ForEach(PredictionOutcome.allCases) { outcome in
                    Button(action: { onSelect(outcome) }) {
                        Text(title(for: outcome))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selected == outcome ? .green : .accentColor)
                    .disabled(event.isLocked)
                }
            }
            if let outcome = event.outcome {
                HStack {
                    Text("Outcome:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title(for: outcome))
                        .font(.caption)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 6)
        // now is driven by parent view model timer
    }

    private func title(for outcome: PredictionOutcome) -> String {
        switch outcome {
        case .homeWin: return "Home"
        case .draw: return "Draw"
        case .awayWin: return "Away"
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}


