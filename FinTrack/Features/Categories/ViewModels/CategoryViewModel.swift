import Foundation
import Observation

/// Drives `CategoriesScreen` and the add/edit form sheet.
/// All state mutations happen on the `@MainActor`.
@Observable
@MainActor
final class CategoryViewModel {

    // MARK: - View State

    enum ViewState {
        case idle
        case loading
        case error(String)
    }

    var viewState: ViewState = .idle

    // MARK: - Category Lists

    /// Categories of type `.expense`, loaded by `loadCategories()`.
    var expenseCategories: [Category] = []
    /// Categories of type `.income`, loaded by `loadCategories()`.
    var incomeCategories: [Category] = []

    // MARK: - Sheet Control

    var showAddSheet: Bool      = false
    var categoryToEdit: Category? = nil   // non-nil → form is in edit mode

    // MARK: - Form Fields

    var formName:  String       = ""
    var formIcon:  String       = "tag.fill"
    var formColor: String       = "#4ECDC4"
    var formType:  CategoryType = .expense

    // MARK: - Dependencies

    private let repository: any CategoryRepository

    init(repository: any CategoryRepository) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Seeds defaults if needed, then fetches both category lists.
    func loadCategories() {
        // TODO: Set viewState = .loading
        // TODO: try repository.seedDefaultsIfNeeded()
        // TODO: expenseCategories = try repository.fetchByType(.expense)
        // TODO: incomeCategories  = try repository.fetchByType(.income)
        // TODO: Set viewState = .idle
        // TODO: On error: set viewState = .error(error.localizedDescription)
    }

    /// Adds a new category or updates the one referenced by `categoryToEdit`.
    /// Validates the form before saving.
    func saveCategory() {
        // TODO: Guard formName is not empty (trimmed), else set viewState = .error("Name is required")
        // TODO: Guard formName.count <= 30, else set viewState = .error("Name must be 30 characters or fewer")
        // TODO: If categoryToEdit != nil → mutate its fields and call repository.update(_:)
        // TODO: Else → create new Category and call repository.add(_:)
        // TODO: Call loadCategories() to refresh lists
        // TODO: Call resetForm() and set showAddSheet = false
        // TODO: On error: set viewState = .error(error.localizedDescription)
    }

    /// Deletes a custom category. No-ops (with error state) if category is a default.
    func deleteCategory(_ category: Category) {
        // TODO: Guard !category.isDefault, else set viewState = .error(CategoryError.cannotDeleteDefault message)
        // TODO: try repository.delete(category)
        // TODO: Call loadCategories() to refresh lists
        // TODO: On error: set viewState = .error(error.localizedDescription)
    }

    /// Resets all form fields to their defaults and clears edit context.
    func resetForm() {
        // TODO: formName      = ""
        // TODO: formIcon      = "tag.fill"
        // TODO: formColor     = "#4ECDC4"
        // TODO: formType      = .expense
        // TODO: categoryToEdit = nil
    }
}
