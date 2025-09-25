import SwiftUI

struct Tournament: Identifiable {
    let id: String
    let title: String
    let entryCost: Int
    let reward: Int
    let durationSeconds: Int
}

final class TournamentsViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = [
        Tournament(id: "t1", title: "Daily Sprint", entryCost: 20, reward: 60, durationSeconds: 180),
        Tournament(id: "t2", title: "Weekly Marathon", entryCost: 50, reward: 200, durationSeconds: 300),
        Tournament(id: "t3", title: "High Roller", entryCost: 100, reward: 500, durationSeconds: 420)
    ]

    @Published var joinedIds: Set<String> = []
    @Published var endsAtById: [String: Date] = [:]
    @Published var resultById: [String: Bool?] = [:] // true won, false lost, nil none yet
    @Published var now: Date = Date()
    @Published var nextResetAt: Date

    private var timer: Timer?

    init() {
        // next reset at next midnight local time
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        self.nextResetAt = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? Date().addingTimeInterval(24*3600)
        startTicking()
    }

    func join(_ t: Tournament) -> Bool {
        let paid = PredictionService.shared.spendPoints(t.entryCost)
        if paid {
            joinedIds.insert(t.id)
            endsAtById[t.id] = Date().addingTimeInterval(TimeInterval(t.durationSeconds))
            resultById[t.id] = nil
        }
        return paid
    }

    func timeRemaining(for t: Tournament) -> TimeInterval? {
        guard let end = endsAtById[t.id] else { return nil }
        return max(0, end.timeIntervalSince(now))
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.now = Date()
            // resolve finished tournaments
            for tid in self.joinedIds {
                if let end = self.endsAtById[tid], self.now >= end, self.resultById[tid] == nil {
                    let win = Bool.random()
                    self.resultById[tid] = win
                    if win, let t = self.tournaments.first(where: { $0.id == tid }) {
                        PredictionService.shared.awardPoints(t.reward)
                    }
                }
            }

            // daily reset
            if self.now >= self.nextResetAt {
                self.resetTournaments()
                let cal = Calendar.current
                let startOfDay = cal.startOfDay(for: self.now)
                self.nextResetAt = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? self.now.addingTimeInterval(24*3600)
            }
        }
    }

    func resetTournaments() {
        // regenerate pool, clear states
        tournaments = [
            Tournament(id: "t1", title: "Daily Sprint", entryCost: 20, reward: 60, durationSeconds: 180),
            Tournament(id: "t2", title: "Weekly Marathon", entryCost: 50, reward: 200, durationSeconds: 300),
            Tournament(id: "t3", title: "High Roller", entryCost: 100, reward: 500, durationSeconds: 420)
        ]
        joinedIds.removeAll()
        endsAtById.removeAll()
        resultById.removeAll()
    }
}

struct TournamentsView: View {
    @StateObject private var viewModel = TournamentsViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.tournaments) { t in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.title).font(.headline)
                        Text("Entry: \(t.entryCost) pts • Reward: \(t.reward) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        statusView(for: t)
                    }
                    Spacer()
                    Button(action: { _ = viewModel.join(t) }) {
                        Text(viewModel.joinedIds.contains(t.id) ? "Joined" : "Join")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.joinedIds.contains(t.id))
                }
            }
            .navigationTitle("Tournaments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Reset in \(formatReset(viewModel.nextResetAt.timeIntervalSince(viewModel.now)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func statusView(for t: Tournament) -> some View {
        if let remaining = viewModel.timeRemaining(for: t), viewModel.joinedIds.contains(t.id) {
            if remaining > 0 {
                Text("Ends in \(_format(remaining))")
                    .font(.caption2)
                    .foregroundColor(.blue)
            } else if let result = viewModel.resultById[t.id] {
                Text(result ?? false ? "You won!" : "You lost")
                    .font(.caption2)
                    .foregroundColor(result ?? false ? .green : .red)
            }
        } else if let result = viewModel.resultById[t.id] {
            Text(result ?? false ? "You won!" : "You lost")
                .font(.caption2)
                .foregroundColor(result ?? false ? .green : .red)
        } else {
            EmptyView()
        }
    }

    private func _format(_ interval: TimeInterval) -> String {
        let s = Int(interval)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private func formatReset(_ interval: TimeInterval) -> String {
        let s = max(0, Int(interval))
        let h = s / 3600
        let m = (s % 3600) / 60
        let r = s % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, r) }
        return String(format: "%02d:%02d", m, r)
    }
}

extension String: @retroactive Identifiable { public var id: String { self } }


