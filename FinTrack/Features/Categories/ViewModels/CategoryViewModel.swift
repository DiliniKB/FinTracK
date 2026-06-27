import Foundation
import Observation

/// Drives `CategoriesScreen` and `CategoryFormSheet`.
/// All state mutations are confined to the `@MainActor`.
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

    private(set) var expenseCategories: [Category] = []
    private(set) var incomeCategories:  [Category] = []

    // MARK: - Sheet Control

    var showAddSheet:    Bool      = false
    var categoryToEdit:  Category? = nil   // non-nil → form opens in edit mode

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

    // MARK: - loadCategories

    /// Seeds default categories on first launch, then refreshes both lists.
    func loadCategories() {
        viewState = .loading
        do {
            try repository.seedDefaultsIfNeeded()
            expenseCategories = try repository.fetchByType(.expense)
            incomeCategories  = try repository.fetchByType(.income)
            viewState = .idle
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - saveCategory

    /// Validates the form, then either creates a new category or updates the one
    /// being edited. Reloads the lists and dismisses the sheet on success.
    func saveCategory() {
        print("saveCategory called, formName: \(formName)")
        let trimmedName = formName.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            viewState = .error("Name is required.")
            return
        }
        guard trimmedName.count <= 30 else {
            viewState = .error("Name must be 30 characters or fewer.")
            return
        }

        do {
            if let existing = categoryToEdit {
                // Edit mode — mutate the live @Model instance; SwiftData tracks the diff.
                existing.name     = trimmedName
                existing.icon     = formIcon
                existing.colorHex = formColor
                existing.type     = formType
                try repository.update(existing)
            } else {
                // Add mode — create a fresh Category and insert it.
                let category = Category(
                    name:     trimmedName,
                    icon:     formIcon,
                    colorHex: formColor,
                    type:     formType
                )
                try repository.add(category)
            }
            loadCategories()
            resetForm()
            showAddSheet = false
        } catch {
            print("save error: \(error)")
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - deleteCategory

    /// Deletes a custom category and reloads the lists.
    /// Sets an error state if the category is a system default.
    func deleteCategory(_ category: Category) {
        do {
            try repository.delete(category)
            loadCategories()
        } catch {
            // CategoryError.cannotDeleteDefault surfaces here with its own
            // localizedDescription; all other errors propagate the same way.
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - resetForm

    /// Clears all form fields back to their defaults and exits edit mode.
    func resetForm() {
        formName       = ""
        formIcon       = "tag.fill"
        formColor      = "#4ECDC4"
        formType       = .expense
        categoryToEdit = nil
    }
}
