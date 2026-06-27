# Budget Module Spec — V1
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
Allow users to set monthly spending limits per expense category, track progress against those limits, and receive local notifications when approaching 80% of any budget.

### Scope
- Create / edit / delete budgets per expense category per month
- Budget progress tracking (spent vs limit)
- Local notification when spending reaches 80% of a budget
- User can navigate to any month to view/set budgets

### Out of Scope
- Income category budgets
- Overall monthly spending cap (V2)
- Budget rollover
- Budget templates

---

## 2. User Stories

| ID | Story |
|---|---|
| BUD-01 | As a user, I can set a monthly budget limit for any expense category |
| BUD-02 | As a user, I can edit or delete an existing budget |
| BUD-03 | As a user, I can see how much I've spent vs my budget for each category |
| BUD-04 | As a user, I see a progress bar showing % of budget used |
| BUD-05 | As a user, I receive a notification when I reach 80% of a budget |
| BUD-06 | As a user, I can navigate between months to view/set budgets |
| BUD-07 | As a user, categories without a budget are shown separately |

---

## 3. Data Model

```swift
@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var categoryName: String      // Denormalized
    var categoryIcon: String      // Denormalized
    var categoryColorHex: String  // Denormalized
    var limitAmount: Double       // Budget cap in LKR
    var month: Date               // Normalized to first day of month (e.g. 2026-06-01)
    var alertFired: Bool          // true once 80% notification has been sent
    var createdAt: Date

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        categoryName: String,
        categoryIcon: String,
        categoryColorHex: String,
        limitAmount: Double,
        month: Date,
        alertFired: Bool = false,
        createdAt: Date = Date()
    )
}
```

---

## 4. Budget Progress (Computed)

Not persisted — computed in ViewModel from Budget + Transactions:

```swift
struct BudgetProgress {
    let budget: Budget
    let spent: Double
    var remaining: Double { budget.limitAmount - spent }
    var percentage: Double { min(spent / budget.limitAmount, 1.0) }
    var isOverBudget: Bool { spent > budget.limitAmount }
    var isApproaching: Bool { percentage >= 0.8 && !isOverBudget }
}
```

---

## 5. Repository Layer

### Protocol
```swift
protocol BudgetRepository {
    func fetchAll() throws -> [Budget]
    func fetchByMonth(_ date: Date) throws -> [Budget]
    func fetchByCategory(_ categoryId: UUID, month: Date) throws -> Budget?
    func add(_ budget: Budget) throws
    func update(_ budget: Budget) throws
    func delete(_ budget: Budget) throws
}
```

### Implementation
```swift
final class SwiftDataBudgetRepository: BudgetRepository {
    private let context: ModelContext

    // fetchByMonth: filter where month == normalizedMonth(date)
    // fetchByCategory: filter by categoryId AND month
    // normalizedMonth: strips to first day of month using Calendar
}
```

---

## 6. Budget Alert Service

```swift
protocol BudgetAlertService {
    func requestPermission() async
    func scheduleApproachingAlert(for budget: Budget, spent: Double) async
    func cancelAlert(for budgetId: UUID)
}

final class LocalBudgetAlertService: BudgetAlertService {
    // Uses UNUserNotificationCenter
    // scheduleApproachingAlert: only fires if budget.alertFired == false
    //   → sends notification: "You've used 80% of your [Category] budget"
    //   → sets budget.alertFired = true via repo
    //   → saves to prevent duplicate notifications
}
```

---

## 7. ViewModel

```swift
@Observable
@MainActor
class BudgetViewModel {

    enum ViewState {
        case idle
        case loading
        case error(String)
    }

    // Display
    var budgetProgressList: [BudgetProgress] = []   // categories WITH budgets
    var unbudgetedCategories: [Category] = []        // expense categories WITHOUT budgets
    var selectedMonth: Date = Date()                  // normalized to first of month
    var viewState: ViewState = .idle

    // Sheet control
    var showAddSheet = false
    var budgetToEdit: Budget? = nil

    // Form fields
    var formCategory: Category? = nil
    var formLimitAmount: String = ""

    // Actions
    func loadBudgets()              // fetch budgets + compute progress from transactions
    func saveBudget()               // add or update
    func deleteBudget(_ budget: Budget)
    func resetForm()
    func goToPreviousMonth()
    func goToNextMonth()
    func checkAndFireAlerts()       // called after loadBudgets — fires notifications if needed

    // Dependencies: BudgetRepository, TransactionRepository, CategoryRepository, BudgetAlertService
}
```

---

## 8. UI Screens

### BudgetScreen (main)

**Header:**
- Month navigator: `< June 2026 >`  (previous/next arrows)
- Current month highlighted

**Budgeted Categories section:**
- List of `BudgetProgressRow` per budget
- Swipe to delete

**Unbudgeted Categories section:**
- Flat list of expense categories with no budget for the month
- Tap → opens AddBudgetSheet with category pre-selected

**+ toolbar button** → opens AddBudgetSheet (no pre-selection)

---

### BudgetProgressRow
- Left: colored category icon
- Center: category name + `Rs. X spent of Rs. Y`
- Right: percentage label (e.g. `64%`)
- Bottom: progress bar
  - Green: < 80%
  - Orange: 80–99%
  - Red: 100%+ (over budget)

---

### BudgetFormSheet (Add / Edit)
- Category picker (expense categories only, filtered to those without a budget for the month — except when editing)
- Amount field (numeric, LKR prefix)
- Month display (read-only — inherits selectedMonth from screen)
- Save / Cancel

---

## 9. Month Normalization

Always strip to first day of month before storing or querying:

```swift
func normalizedMonth(_ date: Date) -> Date {
    let cal = Calendar.current
    return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
}
```

---

## 10. Alert Logic

```swift
// In BudgetViewModel.checkAndFireAlerts()
for progress in budgetProgressList {
    if progress.isApproaching && !progress.budget.alertFired {
        await alertService.scheduleApproachingAlert(
            for: progress.budget,
            spent: progress.spent
        )
        // alertService marks alertFired = true and saves
    }
}
```

Alert resets: if user increases the budget limit, reset `alertFired = false` so they can be notified again at 80% of the new limit.

---

## 11. Edge Cases

| Case | Handling |
|---|---|
| No budgets for selected month | Show empty state + all categories as unbudgeted |
| Category deleted after budget created | Denormalized fields preserve display |
| Budget limit set to zero | Prevent save, show validation error |
| Over budget | Progress bar fills red, no notification (already exceeded) |
| User navigates to future month | Allow — useful for planning ahead |
| Alert already fired, budget increased | Reset alertFired = false |

---

## 12. Notification Payload

```swift
let content = UNMutableNotificationContent()
content.title = "Budget Alert"
content.body  = "You've used 80% of your \(budget.categoryName) budget for \(monthString)."
content.sound = .default

// Trigger immediately (in-app check, not scheduled time)
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
let request = UNNotificationRequest(
    identifier: "budget-alert-\(budget.id.uuidString)",
    content: content,
    trigger: trigger
)
```

---

## 13. File Structure

```
Features/Budget/
├── Models/
│   ├── Budget.swift
│   └── BudgetProgress.swift
├── Repository/
│   ├── BudgetRepository.swift
│   └── SwiftDataBudgetRepository.swift
├── Services/
│   ├── BudgetAlertService.swift
│   └── LocalBudgetAlertService.swift
├── ViewModels/
│   └── BudgetViewModel.swift
└── Views/
    ├── BudgetScreen.swift
    ├── BudgetProgressRow.swift
    └── BudgetFormSheet.swift
```

---

## 14. Acceptance Criteria

- [ ] User can set a budget for any expense category for any month
- [ ] User can edit budget limit
- [ ] User can delete a budget
- [ ] Progress bar shows correct % with correct color
- [ ] Month navigator moves forward and backward
- [ ] Unbudgeted categories listed separately with tap-to-add
- [ ] Notification fires once when spending hits 80%
- [ ] No duplicate notifications for same budget
- [ ] Over budget shown in red
- [ ] LKR formatting throughout
- [ ] Budget.self registered in SwiftData schema

---

## 15. V2 Notes
- AI: "At this rate you'll exceed your Food budget by Rs. 3,200 this month"
- AI: suggest budget amounts based on historical spending
- Overall monthly cap in addition to per-category
