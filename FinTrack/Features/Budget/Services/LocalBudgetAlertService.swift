import Foundation
import UserNotifications

final class LocalBudgetAlertService: BudgetAlertService {
    private let repository: any BudgetRepository
    private let center = UNUserNotificationCenter.current()

    init(repository: any BudgetRepository) {
        self.repository = repository
    }

    func requestPermission() async {
        try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func scheduleApproachingAlert(for budget: Budget, spent: Double) async {
        guard !budget.alertFired else { return }

        let monthString = budget.month.formatted(.dateTime.month(.wide).year())

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.body  = "You've used 80% of your \(budget.categoryName) budget for \(monthString)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget-alert-\(budget.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)

        // Mark alertFired so this notification is never sent twice for the same budget.
        budget.alertFired = true
        try? repository.update(budget)
    }

    func cancelAlert(for budgetId: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["budget-alert-\(budgetId.uuidString)"]
        )
    }
}
