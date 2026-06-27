# Categories Module Spec — V1
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
Allow users to organize transactions under named categories, each with a type (income/expense), icon, and color. System provides sensible defaults; users can add, edit, and delete custom categories.

### Scope
- Predefined default categories (seeded on first launch)
- User-created custom categories
- Edit and delete custom categories (defaults are protected)
- SwiftData persistence

### Out of Scope
- Subcategories
- Category budgets (handled in Budget module)
- Category merging or archiving

---

## 2. User Stories

| ID | Story |
|---|---|
| CAT-01 | As a user, I see default categories on first launch |
| CAT-02 | As a user, I can create a custom category with name, icon, color, and type |
| CAT-03 | As a user, I can edit a custom category |
| CAT-04 | As a user, I can delete a custom category |
| CAT-05 | As a user, I cannot delete or edit default categories |
| CAT-06 | As a user, categories are grouped by type (Income / Expense) |

---

## 3. Data Model

```swift
@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String          // SF Symbol name e.g. "fork.knife"
    var colorHex: String      // Hex string e.g. "#FF6B6B"
    var type: CategoryType    // .income / .expense
    var isDefault: Bool       // true = system default, cannot be edited/deleted
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        type: CategoryType,
        isDefault: Bool = false,
        createdAt: Date = Date()
    )
}

enum CategoryType: String, Codable {
    case income
    case expense
}
```

---

## 4. Default Categories

### Expense
| Name | Icon | Color |
|---|---|---|
| Food & Dining | `fork.knife` | `#FF6B6B` |
| Transport | `car.fill` | `#4ECDC4` |
| Shopping | `bag.fill` | `#45B7D1` |
| Entertainment | `tv.fill` | `#96CEB4` |
| Health | `heart.fill` | `#FF6B9D` |
| Utilities | `bolt.fill` | `#FFEAA7` |
| Education | `book.fill` | `#A29BFE` |
| Other | `ellipsis.circle.fill` | `#B2BEC3` |

### Income
| Name | Icon | Color |
|---|---|---|
| Salary | `briefcase.fill` | `#00B894` |
| Freelance | `laptopcomputer` | `#00CEC9` |
| Investment | `chart.line.uptrend.xyaxis` | `#6C5CE7` |
| Gift | `gift.fill` | `#FD79A8` |
| Other Income | `ellipsis.circle.fill` | `#B2BEC3` |

---

## 5. Repository Layer

### Protocol
```swift
protocol CategoryRepository {
    func fetchAll() throws -> [Category]
    func fetchByType(_ type: CategoryType) throws -> [Category]
    func add(_ category: Category) throws
    func update(_ category: Category) throws
    func delete(_ category: Category) throws
    func seedDefaultsIfNeeded() throws
}
```

### Implementation
```swift
class SwiftDataCategoryRepository: CategoryRepository {
    private let context: ModelContext
    // implement all protocol methods using SwiftData queries
}
```

---

## 6. ViewModel

```swift
@Observable
@MainActor
class CategoryViewModel {

    enum ViewState {
        case idle
        case loading
        case error(String)
    }

    var expenseCategories: [Category] = []
    var incomeCategories: [Category] = []
    var viewState: ViewState = .idle

    // Sheet control
    var showAddSheet = false
    var categoryToEdit: Category? = nil

    // Form fields
    var formName: String = ""
    var formIcon: String = "tag.fill"
    var formColor: String = "#4ECDC4"
    var formType: CategoryType = .expense

    // Actions
    func loadCategories()
    func saveCategory()           // add or update based on categoryToEdit
    func deleteCategory(_ category: Category)
    func resetForm()
}
```

---

## 7. UI Screens

### CategoriesScreen (main list)
- Segmented control: **Expense | Income**
- List of categories per selected type
- Each row: colored icon + name + (edit/delete for custom only)
- `+` button → opens AddCategorySheet
- Swipe to delete (custom only)
- Tap row → opens EditCategorySheet (custom only)

### AddCategorySheet / EditCategorySheet (same view, different mode)
- Text field: Name
- Type picker: Expense / Income
- Icon picker: grid of SF Symbols
- Color picker: preset palette of 10 colors
- Save / Cancel buttons
- Validation: name required, max 30 chars

---

## 8. Seeding Logic

Run `seedDefaultsIfNeeded()` once on app first launch:

```swift
// In SwiftDataCategoryRepository
func seedDefaultsIfNeeded() throws {
    let existing = try fetchAll()
    guard existing.isEmpty else { return }  // already seeded
    // insert all default categories
}
```

Call from `CategoryViewModel.loadCategories()` before fetching.

---

## 9. Edge Cases

| Case | Handling |
|---|---|
| Delete category in use by transactions | Prevent delete, show alert (handle in Transactions module) |
| Duplicate category name | Allow — no uniqueness constraint on name |
| Empty categories list | Show empty state with prompt to add |
| Default category edit attempt | Edit/delete controls hidden for `isDefault == true` |

---

## 10. File Structure

```
Features/Categories/
├── Models/
│   ├── Category.swift
│   └── CategoryType.swift
├── Repository/
│   ├── CategoryRepository.swift         # Protocol
│   └── SwiftDataCategoryRepository.swift
├── ViewModels/
│   └── CategoryViewModel.swift
└── Views/
    ├── CategoriesScreen.swift
    ├── CategoryRowView.swift
    └── CategoryFormSheet.swift
```

---

## 11. Acceptance Criteria

- [ ] Default categories appear on first launch, grouped by type
- [ ] User can add a custom category with name, icon, color, type
- [ ] User can edit a custom category
- [ ] User can delete a custom category via swipe or button
- [ ] Default categories show no edit/delete controls
- [ ] Switching between Income/Expense tabs filters correctly
- [ ] Empty state shown when no categories in selected type
- [ ] Form validates name is not empty before saving

---

## 12. V2 Notes
- Category usage analytics (AI: "You spend most on Food & Dining")
- Smart category suggestion based on transaction description (AI layer)
