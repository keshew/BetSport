import SwiftUI

struct LeaderboardEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let points: Int
}

final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []

    private var timer: Timer?

    func load() {
        var list: [LeaderboardEntry] = []
        let names = [
            "Alex Johnson","Maria Garcia","Liam Smith","Emma Brown","Noah Davis","Olivia Wilson","Ava Taylor","Ethan Martinez","Sophia Anderson","Mason Thomas",
            "Isabella Moore","Logan Jackson","Mia Martin","Lucas Lee","Amelia Perez","James Thompson","Harper White","Benjamin Harris","Evelyn Clark","Elijah Lewis",
            "Charlotte Walker","William Hall","Abigail Allen","Henry Young","Emily King","Jackson Wright","Aiden Scott","Scarlett Green","Daniel Adams","Grace Baker"
        ]
        for (i, name) in names.enumerated() {
            list.append(LeaderboardEntry(id: "\(i+1)", name: name, points: Int.random(in: 500...2000)))
        }
        entries = list.sorted { $0.points > $1.points }
        startUpdating()
    }

    private func startUpdating() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            // nudge random users' points periodically to simulate changes
            var updated = self.entries
            for _ in 0..<3 {
                if let idx = updated.indices.randomElement() {
                    updated[idx] = LeaderboardEntry(id: updated[idx].id, name: updated[idx].name, points: updated[idx].points + Int.random(in: -10...25))
                }
            }
            self.entries = updated.sorted { $0.points > $1.points }
        }
    }
}

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.entries) { entry in
                HStack {
                    Text(entry.name)
                    Spacer()
                    Text("\(entry.points)")
                        .font(.headline)
                }
            }
            .navigationTitle("Leaders")
        }
        .onAppear { viewModel.load() }
    }
}


