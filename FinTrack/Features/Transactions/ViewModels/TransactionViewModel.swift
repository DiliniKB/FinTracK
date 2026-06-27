import Foundation
import Observation

@Observable
@MainActor
class TransactionViewModel {

    enum ViewState {
        case idle
        case loading
        case error(String)
    }

    // MARK: - Display state
    var groupedTransactions: [(date: Date, transactions: [Transaction])] = []
    var monthlySummary: MonthlySummary?
    var selectedFilter: TransactionFilter = .all
    var viewState: ViewState = .idle

    // MARK: - Sheet control
    var showAddSheet = false
    var transactionToEdit: Transaction? = nil

    // MARK: - Form fields
    var formAmount: String = ""
    var formType: CategoryType = .expense
    var formCategory: Category? = nil
    var formPayee: String = ""
    var formNote: String = ""
    var formDate: Date = Date()

    // MARK: - Dependencies
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    // MARK: - Actions

    func loadTransactions() {
        // TODO: Implement — fetch via repository, apply selectedFilter, group by date
    }

    func saveTransaction() {
        // TODO: Implement — validate form, build Transaction, add or update via repository
    }

    func deleteTransaction(_ transaction: Transaction) {
        // TODO: Implement — delete via repository, reload
    }

    func resetForm() {
        // TODO: Implement — clear all form fields to defaults
    }

    func populateForm(from transaction: Transaction) {
        // TODO: Implement — fill form fields from existing transaction for editing
    }

    // MARK: - Helpers

    func groupByDate(_ transactions: [Transaction]) -> [(date: Date, transactions: [Transaction])] {
        // TODO: Implement — group by calendar day, newest first
        []
    }

    func computeMonthlySummary(from transactions: [Transaction]) -> MonthlySummary {
        // TODO: Implement — sum income and expense for the current month
        MonthlySummary(month: Date(), totalIncome: 0, totalExpense: 0)
    }
}
