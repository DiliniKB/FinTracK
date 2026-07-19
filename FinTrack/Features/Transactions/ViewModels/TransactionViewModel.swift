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

    private(set) var groupedTransactions: [(date: Date, transactions: [Transaction])] = []
    private(set) var monthlySummary: MonthlySummary?
    private(set) var allMonthTransactions: [Transaction] = []
    var selectedFilter: TransactionFilter = .all
    var selectedMonth: Date = Calendar.current.startOfMonth(for: Date())
    var viewState: ViewState = .idle

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

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

    // MARK: - Available categories (for picker)

    private(set) var availableCategories: [Category] = []

    // MARK: - Dependencies

    private let transactionRepository: any TransactionRepository
    private let categoryRepository: any CategoryRepository

    init(transactionRepository: any TransactionRepository, categoryRepository: any CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Month navigation

    func goToPreviousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        loadTransactions()
    }

    func goToNextMonth() {
        guard !isCurrentMonth else { return }
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        loadTransactions()
    }

    // MARK: - loadTransactions

    func loadTransactions() {
        viewState = .loading
        do {
            let all = try transactionRepository.fetchByMonth(selectedMonth)
            allMonthTransactions = all
            let filtered: [Transaction]
            switch selectedFilter {
            case .all:     filtered = all
            case .income:  filtered = all.filter { $0.type == .income }
            case .expense: filtered = all.filter { $0.type == .expense }
            }
            groupedTransactions = groupByDate(filtered)
            monthlySummary = computeMonthlySummary(from: all)
            viewState = .idle
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - loadCategories

    func loadCategories() {
        do {
            availableCategories = try categoryRepository.fetchByType(formType)
            // Clear the selected category if it no longer belongs to the current type.
            if let selected = formCategory, selected.type != formType {
                formCategory = nil
            }
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - saveTransaction

    func saveTransaction() {
        let trimmed = formAmount.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let amount = Double(trimmed), amount > 0 else {
            viewState = .error("Enter a valid amount greater than zero.")
            return
        }
        guard let category = formCategory else {
            viewState = .error("Please select a category.")
            return
        }

        do {
            if let existing = transactionToEdit {
                // Edit mode — mutate the live @Model instance; SwiftData tracks the diff.
                existing.amount           = amount
                existing.type             = formType
                existing.categoryId       = category.id
                existing.categoryName     = category.name
                existing.categoryIcon     = category.icon
                existing.categoryColorHex = category.colorHex
                existing.payee            = formPayee
                existing.note             = formNote
                existing.date             = formDate
                try transactionRepository.update(existing)
            } else {
                let transaction = Transaction(
                    amount:           amount,
                    type:             formType,
                    categoryId:       category.id,
                    categoryName:     category.name,
                    categoryIcon:     category.icon,
                    categoryColorHex: category.colorHex,
                    payee:            formPayee,
                    note:             formNote,
                    date:             formDate
                )
                try transactionRepository.add(transaction)
            }
            resetForm()
            showAddSheet = false
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - deleteTransaction

    func deleteTransaction(_ transaction: Transaction) {
        do {
            try transactionRepository.delete(transaction)
            loadTransactions()
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - resetForm

    func resetForm() {
        formAmount        = ""
        formType          = .expense
        formCategory      = nil
        formPayee         = ""
        formNote          = ""
        formDate          = isCurrentMonth ? Date() : selectedMonth
        transactionToEdit = nil
    }

    // MARK: - populateForm

    func populateForm(from transaction: Transaction) {
        formAmount        = String(transaction.amount)
        formType          = transaction.type
        formPayee         = transaction.payee
        formNote          = transaction.note
        formDate          = transaction.date
        transactionToEdit = transaction
        // Resolve the live Category object from the repository so the picker has a selection.
        formCategory = (try? categoryRepository.fetchAll())?.first { $0.id == transaction.categoryId }
        loadCategories()
    }

    // MARK: - groupByDate

    func groupByDate(_ transactions: [Transaction]) -> [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        var map: [Date: [Transaction]] = [:]
        for txn in transactions {
            let day = calendar.startOfDay(for: txn.date)
            map[day, default: []].append(txn)
        }
        return map
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, transactions: $0.value) }
    }

    // MARK: - computeMonthlySummary

    func computeMonthlySummary(from transactions: [Transaction]) -> MonthlySummary {
        let income  = transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return MonthlySummary(month: selectedMonth, totalIncome: income, totalExpense: expense)
    }
}
