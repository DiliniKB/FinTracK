import Foundation
import SwiftData

class SwiftDataTransactionRepository: TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchAll() throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByType(_ type: CategoryType) throws -> [Transaction] {
        // #Predicate cannot traverse .rawValue on a Codable enum in SwiftData —
        // the generated keypath cannot be translated into a valid SQLite WHERE clause.
        // Filtering in memory after fetchAll() is the correct workaround (mirrors CategoryRepository).
        try fetchAll().filter { $0.type == type }
    }

    func fetchByMonth(_ date: Date) throws -> [Transaction] {
        let calendar = Calendar.current
        guard
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
            let end   = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start)
        else {
            return []
        }
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy:    [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Write

    func add(_ transaction: Transaction) throws {
        context.insert(transaction)
        try context.save()
    }

    func update(_ transaction: Transaction) throws {
        // Caller mutates @Model properties directly; SwiftData tracks changes automatically.
        try context.save()
    }

    func delete(_ transaction: Transaction) throws {
        context.delete(transaction)
        try context.save()
    }
}
