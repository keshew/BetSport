import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if !granted {
                // silently ignore for now
            }
        } catch {
            // ignore
        }
    }

    func scheduleEventReminder(event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Скоро начало"
        content.body = "\(event.homeTeam) vs \(event.awayTeam) начинается скоро. Успей сделать прогноз!"
        content.sound = .default

        let triggerDate = event.startDate.addingTimeInterval(-120) // 2 minutes before
        let interval = max(1, triggerDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "event_\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}


