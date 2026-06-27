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
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByType(_ type: CategoryType) throws -> [Category] {
        // #Predicate cannot traverse .rawValue on a Codable enum stored by SwiftData —
        // the macro generates a keypath expression that SwiftData cannot translate into
        // a valid SQLite WHERE clause, causing it to silently return empty results.
        // Filtering in memory after fetchAll() is the correct workaround.
        try fetchAll().filter { $0.type == type }
    }

    // MARK: - Write

    func add(_ category: Category) throws {
        context.insert(category)
        try context.save()
    }

    func update(_ category: Category) throws {
        guard !category.isDefault else {
            throw CategoryError.cannotEditDefault
        }
        // The caller mutates the @Model instance's properties directly before
        // calling update(). SwiftData tracks those changes automatically;
        // we only need to persist them.
        try context.save()
    }

    func delete(_ category: Category) throws {
        guard !category.isDefault else {
            throw CategoryError.cannotDeleteDefault
        }
        context.delete(category)
        try context.save()
    }

    // MARK: - Seeding

    func seedDefaultsIfNeeded() throws {
        let existing = try fetchAll()
        guard existing.isEmpty else { return }

        for seed in Self.defaultCategories {
            context.insert(seed)
        }
        try context.save()
    }

    // MARK: - Default category definitions (spec §4)

    private static let defaultCategories: [Category] = [
        // Expense
        Category(name: "Food & Dining",  icon: "fork.knife",                  colorHex: "#FF6B6B", type: .expense, isDefault: true),
        Category(name: "Transport",      icon: "car.fill",                    colorHex: "#4ECDC4", type: .expense, isDefault: true),
        Category(name: "Shopping",       icon: "bag.fill",                    colorHex: "#45B7D1", type: .expense, isDefault: true),
        Category(name: "Entertainment",  icon: "tv.fill",                     colorHex: "#96CEB4", type: .expense, isDefault: true),
        Category(name: "Health",         icon: "heart.fill",                  colorHex: "#FF6B9D", type: .expense, isDefault: true),
        Category(name: "Utilities",      icon: "bolt.fill",                   colorHex: "#FFEAA7", type: .expense, isDefault: true),
        Category(name: "Education",      icon: "book.fill",                   colorHex: "#A29BFE", type: .expense, isDefault: true),
        Category(name: "Other",          icon: "ellipsis.circle.fill",        colorHex: "#B2BEC3", type: .expense, isDefault: true),
        // Income
        Category(name: "Salary",         icon: "briefcase.fill",              colorHex: "#00B894", type: .income,  isDefault: true),
        Category(name: "Freelance",      icon: "laptopcomputer",              colorHex: "#00CEC9", type: .income,  isDefault: true),
        Category(name: "Investment",     icon: "chart.line.uptrend.xyaxis",   colorHex: "#6C5CE7", type: .income,  isDefault: true),
        Category(name: "Gift",           icon: "gift.fill",                   colorHex: "#FD79A8", type: .income,  isDefault: true),
        Category(name: "Other Income",   icon: "ellipsis.circle.fill",        colorHex: "#B2BEC3", type: .income,  isDefault: true),
    ]
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
