import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {

    enum ViewState { case idle, loading, error(String) }

    // MARK: - Display state

    private(set) var monthlySummary: MonthlySummary?
    private(set) var categoryBreakdown: [CategorySpend] = []
    private(set) var budgetProgressList: [BudgetProgress] = []
    private(set) var recentTransactions: [Transaction] = []
    var selectedMonth: Date
    var viewState: ViewState = .idle

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Dependencies

    private let transactionRepository: any TransactionRepository
    private let budgetRepository: any BudgetRepository

    init(transactionRepository: any TransactionRepository,
         budgetRepository: any BudgetRepository) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        let cal = Calendar.current
        self.selectedMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
    }

    // MARK: - Load

    func loadDashboard() {
        viewState = .loading
        do {
            let allTxns = try transactionRepository.fetchByMonth(selectedMonth)
            let budgets  = try budgetRepository.fetchByMonth(selectedMonth)

            // Summary
            let income  = allTxns.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }
            let expense = allTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            monthlySummary = MonthlySummary(month: selectedMonth, totalIncome: income, totalExpense: expense)

            // Category breakdown (expenses only)
            categoryBreakdown = buildCategoryBreakdown(from: allTxns, totalExpense: expense)

            // Budget progress
            var spentMap: [UUID: Double] = [:]
            for txn in allTxns where txn.type == .expense {
                spentMap[txn.categoryId, default: 0] += txn.amount
            }
            budgetProgressList = budgets.map { BudgetProgress(budget: $0, spent: spentMap[$0.categoryId] ?? 0) }

            // Recent transactions (newest 5)
            recentTransactions = Array(allTxns.sorted { $0.date > $1.date }.prefix(5))

            viewState = .idle
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - Month navigation

    func goToPreviousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = normalizedMonth(prev)
            loadDashboard()
        }
    }

    func goToNextMonth() {
        guard !isCurrentMonth else { return }
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = normalizedMonth(next)
            loadDashboard()
        }
    }

    // MARK: - Private helpers

    private func buildCategoryBreakdown(from txns: [Transaction], totalExpense: Double) -> [CategorySpend] {
        guard totalExpense > 0 else { return [] }

        // Aggregate by category
        var map: [UUID: (name: String, colorHex: String, icon: String, amount: Double)] = [:]
        for txn in txns where txn.type == .expense {
            if var entry = map[txn.categoryId] {
                entry.amount += txn.amount
                map[txn.categoryId] = entry
            } else {
                map[txn.categoryId] = (txn.categoryName, txn.categoryColorHex, txn.categoryIcon, txn.amount)
            }
        }

        var items = map.map { id, v in
            CategorySpend(id: id, name: v.name, colorHex: v.colorHex, icon: v.icon,
                          amount: v.amount, percentage: v.amount / totalExpense)
        }.sorted { $0.amount > $1.amount }

        // Merge categories below 5% share into "Other"
        let significant = items.filter { $0.percentage >= 0.05 }
        let minor       = items.filter { $0.percentage < 0.05 }

        if !minor.isEmpty {
            let otherAmount = minor.reduce(0) { $0 + $1.amount }
            let other = CategorySpend(
                id:         UUID(),
                name:       "Other",
                colorHex:   "#8E8E93",
                icon:       "ellipsis.circle",
                amount:     otherAmount,
                percentage: otherAmount / totalExpense
            )
            items = significant + [other]
        } else {
            items = significant
        }

        return items
    }

    private func normalizedMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }
}
