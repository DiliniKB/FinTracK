# Transactions Module Spec — V1
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
Core module of the app. Allows users to manually log income and expense transactions, view transaction history, and manage individual entries.

### Scope
- Add transaction (manual entry)
- Edit transaction
- Delete transaction
- Transaction list with date grouping
- Filter by type (income/expense/all)
- LKR currency throughout

### Out of Scope
- SMS parsing (separate module)
- Search (V2)
- Export (V2)
- Recurring transactions (V2)

---

## 2. User Stories

| ID | Story |
|---|---|
| TXN-01 | As a user, I can add a transaction with amount, category, date, note, and payee |
| TXN-02 | As a user, I can edit an existing transaction |
| TXN-03 | As a user, I can delete a transaction |
| TXN-04 | As a user, I see transactions grouped by date, newest first |
| TXN-05 | As a user, I can filter transactions by All / Income / Expense |
| TXN-06 | As a user, income amounts show in green, expenses in red |
| TXN-07 | As a user, I see a monthly summary (total income, total expense, net) at the top |

---

## 3. Data Model

```swift
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double           // Always positive; type determines sign
    var type: CategoryType       // .income / .expense
    var categoryId: UUID         // Reference to Category
    var categoryName: String     // Denormalized — survives category deletion
    var categoryIcon: String     // Denormalized
    var categoryColorHex: String // Denormalized
    var payee: String            // Who paid / was paid
    var note: String             // Optional note, can be empty
    var date: Date
    var createdAt: Date
    var source: TransactionSource // .manual / .sms

    init(
        id: UUID = UUID(),
        amount: Double,
        type: CategoryType,
        categoryId: UUID,
        categoryName: String,
        categoryIcon: String,
        categoryColorHex: String,
        payee: String = "",
        note: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        source: TransactionSource = .manual
    )
}

enum TransactionSource: String, Codable {
    case manual
    case sms     // populated by SMS parsing module
}
```

> **Why denormalize category fields?**
> If a category is deleted, transactions retain their display info.
> SwiftData doesn't support optional relationships well in V1.

---

## 4. Monthly Summary

```swift
struct MonthlySummary {
    let month: Date
    let totalIncome: Double
    let totalExpense: Double
    var net: Double { totalIncome - totalExpense }
}
```

Computed in ViewModel from current month's transactions — not persisted.

---

## 5. Repository Layer

### Protocol
```swift
protocol TransactionRepository {
    func fetchAll() throws -> [Transaction]
    func fetchByType(_ type: CategoryType) throws -> [Transaction]
    func fetchByMonth(_ date: Date) throws -> [Transaction]
    func add(_ transaction: Transaction) throws
    func update(_ transaction: Transaction) throws
    func delete(_ transaction: Transaction) throws
}
```

### Implementation
```swift
class SwiftDataTransactionRepository: TransactionRepository {
    private let context: ModelContext
    // All methods use FetchDescriptor with sortBy date descending
}
```

---

## 6. ViewModel

```swift
@Observable
@MainActor
class TransactionViewModel {

    enum ViewState {
        case idle
        case loading
        case error(String)
    }

    // Display
    var groupedTransactions: [(date: Date, transactions: [Transaction])] = []
    var monthlySummary: MonthlySummary?
    var selectedFilter: TransactionFilter = .all
    var viewState: ViewState = .idle

    // Sheet control
    var showAddSheet = false
    var transactionToEdit: Transaction? = nil

    // Form fields
    var formAmount: String = ""          // String for TextField input
    var formType: CategoryType = .expense
    var formCategory: Category? = nil
    var formPayee: String = ""
    var formNote: String = ""
    var formDate: Date = Date()

    // Actions
    func loadTransactions()
    func saveTransaction()
    func deleteTransaction(_ transaction: Transaction)
    func resetForm()
    func populateForm(from transaction: Transaction)

    // Helpers
    func groupByDate(_ transactions: [Transaction]) -> [(date: Date, transactions: [Transaction])]
    func computeMonthlySummary(from transactions: [Transaction]) -> MonthlySummary
}

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
}
```

---

## 7. UI Screens

### TransactionsScreen (main list)
- **Top card:** Monthly summary — Income / Expense / Net in LKR
- **Filter bar:** All | Income | Expense (segmented or chip style)
- **List:** Transactions grouped by date header (e.g. "Today", "Yesterday", "12 Jun 2026")
- Each row: `TransactionRowView`
- Swipe to delete
- Tap row → edit sheet
- `+` toolbar button → add sheet
- Empty state when no transactions

### TransactionRowView
- Left: colored category icon circle
- Center: category name (bold) + payee (secondary)
- Right: amount in LKR (green for income, red for expense)
- Subtitle: note if not empty

### TransactionFormSheet (Add / Edit)
- Amount field (numeric keyboard, LKR prefix)
- Type toggle: Expense / Income (changes category list)
- Category picker (shows filtered categories by type)
- Date picker
- Payee field
- Note field (multiline)
- Save / Cancel

---

## 8. LKR Formatting

```swift
// Core/Extensions/NumberFormatter+LKR.swift
extension NumberFormatter {
    static let lkr: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "LKR"
        f.currencySymbol = "Rs."
        f.maximumFractionDigits = 2
        return f
    }()
}

// Usage
NumberFormatter.lkr.string(from: NSNumber(value: amount)) ?? "Rs. 0.00"
```

---

## 9. Date Grouping Logic

```swift
// Group header labels
func headerLabel(for date: Date) -> String {
    if Calendar.current.isDateInToday(date)     { return "Today" }
    if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
    return date.formatted(.dateTime.day().month(.wide).year())
}
```

---

## 10. Edge Cases

| Case | Handling |
|---|---|
| Amount is zero | Prevent save, show validation error |
| Amount is non-numeric | Prevent save, show validation error |
| No category selected | Prevent save, show validation error |
| Category deleted after transaction created | Denormalized fields preserve display |
| Empty transactions list | Show empty state with prompt |
| Delete last transaction in a date group | Remove the group header too |

---

## 11. File Structure

```
Features/Transactions/
├── Models/
│   ├── Transaction.swift
│   ├── TransactionSource.swift
│   ├── TransactionFilter.swift
│   └── MonthlySummary.swift
├── Repository/
│   ├── TransactionRepository.swift
│   └── SwiftDataTransactionRepository.swift
├── ViewModels/
│   └── TransactionViewModel.swift
└── Views/
    ├── TransactionsScreen.swift
    ├── TransactionRowView.swift
    └── TransactionFormSheet.swift

Core/Extensions/
└── NumberFormatter+LKR.swift
```

---

## 12. Acceptance Criteria

- [ ] User can add a transaction with all fields
- [ ] User can edit a transaction
- [ ] User can delete a transaction via swipe
- [ ] Transactions grouped by date, newest first
- [ ] Filter works for All / Income / Expense
- [ ] Income shown in green, expense in red
- [ ] Monthly summary updates correctly
- [ ] Amount validation prevents zero/non-numeric
- [ ] Category required before save
- [ ] LKR formatting throughout (Rs. X,XXX.00)
- [ ] Empty state shown when no transactions

---

## 13. V2 Notes
- AI: spending pattern analysis per category
- AI: anomaly detection (unusual spend)
- SMS parsing feeds transactions via `source: .sms`
- Search and filter by date range
