import Foundation

protocol BudgetAlertService {
    func requestPermission() async
    func scheduleApproachingAlert(for budget: Budget, spent: Double) async
    func cancelAlert(for budgetId: UUID)
}
