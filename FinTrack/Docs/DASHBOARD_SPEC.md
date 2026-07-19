# Dashboard Screen Spec — V1
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
The Dashboard is the app's home tab. It gives the user a quick financial snapshot of the selected month: income vs expense summary, a donut chart of spending by category, budget health at a glance, and recent transactions.

### Design Principles
- Read-only — no data entry happens on Dashboard
- Mirrors the month navigator pattern from Transactions and Budgets
- Reuses existing data layer (no new SwiftData models needed)
- Tapping a section navigates to the relevant full screen (future V2)

---

## 2. Screen Layout

```
┌─────────────────────────────────────┐
│  Navigation Title: "Dashboard"       │
├─────────────────────────────────────┤
│  < June 2026 >          (navigator)  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │  Income  │  Expense  │  Net   │  │  ← MonthlySummaryCard
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  Spending by Category               │
│  ┌───────────────────────────────┐  │
│  │        [Donut Chart]          │  │
│  │   centre: total expense       │  │
│  └───────────────────────────────┘  │
│  ● Food & Dining   Rs. 8,500  42%   │
│  ● Transport       Rs. 3,200  16%   │
│  ● Shopping        Rs. 2,800  14%   │
│  ● Other           Rs. 5,700  28%   │
├─────────────────────────────────────┤
│  Budget Health                      │
│  Food & Dining  ████░░  67%  ↻     │
│  Transport      ██████ 125%  ↻     │
│  Shopping       ███░░░  52%        │
├─────────────────────────────────────┤
│  Recent Transactions                │
│  Keells      Food  -Rs. 1,200      │
│  Dialog      Utils -Rs. 2,500      │
│  Salary      Inc   +Rs. 85,000     │
│  …  (max 5 rows)                   │
└─────────────────────────────────────┘
```

---

## 3. Components

### 3.1 Month Navigator
- Same `< Month Year >` HStack as `TransactionsScreen` and `BudgetScreen`
- Right chevron disabled when `selectedMonth` is the current month
- Changing month reloads all four sections

### 3.2 Monthly Summary Card
- Reuses `MonthlySummaryCard` from `TransactionsScreen`
- Shows Income (green), Expense (red), Net (green/red)

### 3.3 Spending Donut Chart (SwiftUI Charts)
- `Chart` with `.chartStyle(.pie)` / `SectorMark`
- One sector per expense category with its `categoryColorHex`
- Centre annotation: total expense amount (bold)
- Below chart: legend list sorted by amount descending
  - Color dot · Category name · Amount · Percentage
- "Other" bucket for categories below 5% share (keeps chart readable)
- Empty state: "No expenses this month" placeholder instead of chart

### 3.4 Budget Health
- Compact version of `BudgetProgressRow` — no category icon circle, smaller font
- Shows all budgets for the selected month
- Over-budget rows highlighted red; ↻ icon for recurring budgets
- "No budgets set" placeholder if list is empty

### 3.5 Recent Transactions
- Last 5 transactions (all types) sorted by date descending
- Each row: payee · category icon · ± amount (green income / red expense)
- "No transactions this month" placeholder if empty

---

## 4. Data Flow

```
DashboardViewModel
  ├── selectedMonth: Date
  ├── monthlySummary: MonthlySummary?
  ├── categoryBreakdown: [CategorySpend]     ← computed from transactions
  ├── budgetProgressList: [BudgetProgress]
  └── recentTransactions: [Transaction]      ← last 5 of the month

struct CategorySpend: Identifiable {
    let id: UUID            // categoryId
    let name: String
    let colorHex: String
    let icon: String
    let amount: Double
    var percentage: Double  // of total expense
}
```

`DashboardViewModel.loadDashboard()` performs:
1. `transactionRepository.fetchByMonth(selectedMonth)` → derive summary + categoryBreakdown + recentTransactions
2. `budgetRepository.fetchByMonth(selectedMonth)` → build budgetProgressList (same logic as BudgetViewModel)

No writes — ViewModel is read-only.

---

## 5. ViewModel

```swift
@Observable
@MainActor
final class DashboardViewModel {

    enum ViewState { case idle, loading, error(String) }

    private(set) var monthlySummary: MonthlySummary?
    private(set) var categoryBreakdown: [CategorySpend] = []
    private(set) var budgetProgressList: [BudgetProgress] = []
    private(set) var recentTransactions: [Transaction] = []
    var selectedMonth: Date
    var viewState: ViewState = .idle

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private let transactionRepository: any TransactionRepository
    private let budgetRepository: any BudgetRepository

    func loadDashboard() { ... }
    func goToPreviousMonth() { ... }
    func goToNextMonth() { ... }
}
```

---

## 6. File Structure

```
Features/Dashboard/
├── Models/
│   └── CategorySpend.swift
├── ViewModels/
│   └── DashboardViewModel.swift
└── Views/
    ├── DashboardScreen.swift
    ├── SpendingDonutChart.swift       # Chart + legend
    ├── DashboardBudgetRow.swift       # Compact budget progress row
    └── DashboardTransactionRow.swift  # Compact transaction row
```

---

## 7. Acceptance Criteria

- [ ] Month navigator changes all four sections simultaneously
- [ ] Donut chart renders with correct colours and proportions
- [ ] Centre of donut shows total expense for the month
- [ ] Categories below 5% share are merged into "Other"
- [ ] Budget rows show real percentage (e.g. 125%) and bar capped at 100%
- [ ] Recurring budget rows display ↻ indicator
- [ ] Recent transactions limited to 5, sorted newest first
- [ ] All sections show appropriate empty-state placeholders
- [ ] Loading overlay shown during data fetch
- [ ] Dashboard always opens to the current month on first load

---

## 8. V2 Notes
- Tap budget row → navigate to Budgets tab at that month
- Tap "Recent Transactions" header → navigate to Transactions tab
- Weekly bar chart (7-day spend) above the donut
- Net worth trend line across months
