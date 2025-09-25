import Foundation

final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUser: UserProfile?

    private let userKey = "auth.user"

    private init() {
        if let data = UserDefaults.standard.data(forKey: userKey), let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
        }
    }

    func signIn(displayName: String) {
        let profile = UserProfile(id: UUID().uuidString, displayName: displayName, totalPoints: PredictionService.shared.currentPoints())
        currentUser = profile
        persist(profile)
        NotificationCenter.default.post(name: .predictionsUpdated, object: nil)
    }

    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    private func persist(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }
}


