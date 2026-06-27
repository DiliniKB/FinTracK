import Foundation
import SwiftData

/// V1 implementation of `CategoryRepository` backed by SwiftData.
final class SwiftDataCategoryRepository: CategoryRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchAll() throws -> [Category] {
        // TODO: Build a FetchDescriptor<Category> with no predicate, sorted by name
        // TODO: Return context.fetch(descriptor)
        return []
    }

    func fetchByType(_ type: CategoryType) throws -> [Category] {
        // TODO: Build a FetchDescriptor<Category> with predicate: #Predicate { $0.type == type }
        // TODO: Sort by name
        // TODO: Return context.fetch(descriptor)
        return []
    }

    // MARK: - Write

    func add(_ category: Category) throws {
        // TODO: context.insert(category)
        // TODO: try context.save()
    }

    func update(_ category: Category) throws {
        // TODO: Guard category.isDefault == false, else throw CategoryError.cannotEditDefault
        // TODO: Mutate fields on the passed-in @Model instance (SwiftData tracks changes automatically)
        // TODO: try context.save()
    }

    func delete(_ category: Category) throws {
        // TODO: Guard category.isDefault == false, else throw CategoryError.cannotDeleteDefault
        // TODO: context.delete(category)
        // TODO: try context.save()
    }

    // MARK: - Seeding

    func seedDefaultsIfNeeded() throws {
        // TODO: Call fetchAll(); guard existing.isEmpty else return
        // TODO: Insert all default categories defined in Category+Defaults.swift (or inline below)
        // TODO: try context.save()

        // Default expense categories (spec §4):
        // ("Food & Dining", "fork.knife",           "#FF6B6B", .expense)
        // ("Transport",     "car.fill",              "#4ECDC4", .expense)
        // ("Shopping",      "bag.fill",              "#45B7D1", .expense)
        // ("Entertainment", "tv.fill",               "#96CEB4", .expense)
        // ("Health",        "heart.fill",            "#FF6B9D", .expense)
        // ("Utilities",     "bolt.fill",             "#FFEAA7", .expense)
        // ("Education",     "book.fill",             "#A29BFE", .expense)
        // ("Other",         "ellipsis.circle.fill",  "#B2BEC3", .expense)

        // Default income categories (spec §4):
        // ("Salary",        "briefcase.fill",                   "#00B894", .income)
        // ("Freelance",     "laptopcomputer",                   "#00CEC9", .income)
        // ("Investment",    "chart.line.uptrend.xyaxis",        "#6C5CE7", .income)
        // ("Gift",          "gift.fill",                        "#FD79A8", .income)
        // ("Other Income",  "ellipsis.circle.fill",             "#B2BEC3", .income)
    }
}

// MARK: - Repository Errors

enum CategoryError: LocalizedError {
    case cannotEditDefault
    case cannotDeleteDefault

    var errorDescription: String? {
        switch self {
        case .cannotEditDefault:
            return "Default categories cannot be edited."
        case .cannotDeleteDefault:
            return "Default categories cannot be deleted."
        }
    }
}
