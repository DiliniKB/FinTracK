import Foundation
import SwiftData

final class SwiftDataBudgetRepository: BudgetRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchAll() throws -> [Budget] {
        let descriptor = FetchDescriptor<Budget>(
            sortBy: [SortDescriptor(\.month, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByMonth(_ date: Date) throws -> [Budget] {
        let target = normalizedMonth(date)
        // #Predicate on Date equality works because month is always stored normalized.
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.month == target },
            sortBy: [SortDescriptor(\.categoryName)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByCategory(_ categoryId: UUID, month: Date) throws -> Budget? {
        let target = normalizedMonth(month)
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.categoryId == categoryId && $0.month == target }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Write

    func add(_ budget: Budget) throws {
        context.insert(budget)
        try context.save()
    }

    func update(_ budget: Budget) throws {
        try context.save()
    }

    func delete(_ budget: Budget) throws {
        context.delete(budget)
        try context.save()
    }

    // MARK: - Helpers

    func normalizedMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }
}
