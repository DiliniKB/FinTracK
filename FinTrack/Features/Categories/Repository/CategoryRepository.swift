import Foundation

/// Defines all persistence operations for the Categories module.
/// V1: implemented by `SwiftDataCategoryRepository`.
/// V2: swap for a remote-backed implementation — no ViewModel changes required.
protocol CategoryRepository {

    /// Returns all categories regardless of type, sorted by name.
    func fetchAll() throws -> [Category]

    /// Returns categories filtered to the given type.
    func fetchByType(_ type: CategoryType) throws -> [Category]

    /// Inserts a new category into the store.
    func add(_ category: Category) throws

    /// Persists changes to an existing category.
    /// - Throws: if `category.isDefault == true` (edit not permitted).
    func update(_ category: Category) throws

    /// Removes a category from the store.
    /// - Throws: if `category.isDefault == true` (delete not permitted).
    func delete(_ category: Category) throws

    /// Seeds the predefined default categories on first launch.
    /// No-ops if the store already contains categories.
    func seedDefaultsIfNeeded() throws
}
