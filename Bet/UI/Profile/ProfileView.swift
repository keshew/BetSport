import SwiftUI

struct ProfileView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var wins: Int = 0
    @State private var losses: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let user = auth.currentUser {
                    VStack(spacing: 8) {
                        Text(user.displayName)
                            .font(.title2)
                        Text("Points: \(PredictionService.shared.currentPoints())")
                            .font(.headline)
                    }
                    statsSection
                    Button("Sign out") { auth.signOut() }
                        .buttonStyle(.bordered)
                } else {
                    SignInView()
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .onReceive(NotificationCenter.default.publisher(for: .predictionsUpdated)) { _ in
                recalcStats()
            }
            .onAppear { recalcStats() }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            HStack {
                StatTile(title: "Wins", value: "\(wins)")
                StatTile(title: "Losses", value: "\(losses)")
                StatTile(title: "Accuracy", value: accuracyString)
            }
        }
    }

    private var accuracyString: String {
        let total = wins + losses
        guard total > 0 else { return "-" }
        let acc = Double(wins) / Double(total)
        return String(format: "%.0f%%", acc * 100)
    }

    private func recalcStats() {
        let userId = auth.currentUser?.id ?? "guest"
        let preds = PredictionService.shared.loadPredictions().filter { $0.userId == userId }
        var w = 0, l = 0
        for p in preds {
            if let isCorrect = p.isCorrect {
                if isCorrect { w += 1 } else { l += 1 }
            }
        }
        wins = w
        losses = l
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct SignInView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var name: String = ""

    var body: some View {
        VStack(spacing: 12) {
            TextField("Nickname", text: $name)
                .textFieldStyle(.roundedBorder)
            Button("Continue") {
                guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                auth.signIn(displayName: name)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}


