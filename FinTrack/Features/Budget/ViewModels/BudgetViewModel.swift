import Foundation
import Observation

@Observable
@MainActor
class BudgetViewModel {

    enum ViewState {
        case idle
        case loading
        case error(String)
    }

    // MARK: - Display state

    private(set) var budgetProgressList: [BudgetProgress] = []
    private(set) var unbudgetedCategories: [Category] = []
    var selectedMonth: Date
    var viewState: ViewState = .idle

    // MARK: - Sheet control

    var showAddSheet = false
    var budgetToEdit: Budget? = nil

    // MARK: - Form fields

    var formCategory: Category? = nil
    var formLimitAmount: String = ""

    // MARK: - Dependencies

    private let budgetRepository: any BudgetRepository
    private let transactionRepository: any TransactionRepository
    private let categoryRepository: any CategoryRepository
    private let alertService: any BudgetAlertService

    init(
        budgetRepository: any BudgetRepository,
        transactionRepository: any TransactionRepository,
        categoryRepository: any CategoryRepository,
        alertService: any BudgetAlertService
    ) {
        self.budgetRepository     = budgetRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository   = categoryRepository
        self.alertService         = alertService
        self.selectedMonth        = normalizedMonth(Date())
    }

    // MARK: - loadBudgets

    func loadBudgets() {
        viewState = .loading
        do {
            let budgets = try budgetRepository.fetchByMonth(selectedMonth)
            let transactions = try transactionRepository.fetchByMonth(selectedMonth)
            let allExpenseCategories = try categoryRepository.fetchByType(.expense)

            // Compute spent per categoryId from transactions for the selected month.
            var spentMap: [UUID: Double] = [:]
            for txn in transactions where txn.type == .expense {
                spentMap[txn.categoryId, default: 0] += txn.amount
            }

            budgetProgressList = budgets.map { budget in
                BudgetProgress(budget: budget, spent: spentMap[budget.categoryId] ?? 0)
            }

            // Categories that have no budget entry for this month.
            let budgetedIds = Set(budgets.map(\.categoryId))
            unbudgetedCategories = allExpenseCategories.filter { !budgetedIds.contains($0.id) }

            viewState = .idle
            Task { await checkAndFireAlerts() }
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - saveBudget

    func saveBudget() {
        let trimmed = formLimitAmount.trimmingCharacters(in: .whitespaces)
        guard let limit = Double(trimmed), limit > 0 else {
            viewState = .error("Enter a valid limit greater than zero.")
            return
        }
        guard let category = formCategory else {
            viewState = .error("Please select a category.")
            return
        }

        do {
            if let existing = budgetToEdit {
                let limitIncreased = limit > existing.limitAmount
                existing.limitAmount      = limit
                existing.categoryId       = category.id
                existing.categoryName     = category.name
                existing.categoryIcon     = category.icon
                existing.categoryColorHex = category.colorHex
                // Reset alert so user gets notified again at 80% of the new higher limit.
                if limitIncreased { existing.alertFired = false }
                try budgetRepository.update(existing)
            } else {
                let budget = Budget(
                    categoryId:       category.id,
                    categoryName:     category.name,
                    categoryIcon:     category.icon,
                    categoryColorHex: category.colorHex,
                    limitAmount:      limit,
                    month:            normalizedMonth(selectedMonth)
                )
                try budgetRepository.add(budget)
            }
            loadBudgets()
            resetForm()
            showAddSheet = false
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - deleteBudget

    func deleteBudget(_ budget: Budget) {
        do {
            alertService.cancelAlert(for: budget.id)
            try budgetRepository.delete(budget)
            loadBudgets()
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - resetForm

    func resetForm() {
        formCategory    = nil
        formLimitAmount = ""
        budgetToEdit    = nil
    }

    // MARK: - Month navigation

    func goToPreviousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = normalizedMonth(prev)
            loadBudgets()
        }
    }

    func goToNextMonth() {
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = normalizedMonth(next)
            loadBudgets()
        }
    }

    // MARK: - Permission request (called once on first screen appear)

    func requestAlertPermission() async {
        await alertService.requestPermission()
    }

    // MARK: - Alert checking

    func checkAndFireAlerts() async {
        for progress in budgetProgressList where progress.isApproaching && !progress.budget.alertFired {
            await alertService.scheduleApproachingAlert(for: progress.budget, spent: progress.spent)
        }
    }

    // MARK: - Helpers

    private func normalizedMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }
}
