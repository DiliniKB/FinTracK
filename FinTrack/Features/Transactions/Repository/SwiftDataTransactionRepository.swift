import Foundation
import SwiftData

class SwiftDataTransactionRepository: TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Transaction] {
        // TODO: Implement — FetchDescriptor sorted by date descending
        []
    }

    func fetchByType(_ type: CategoryType) throws -> [Transaction] {
        // TODO: Implement — filter by type predicate
        []
    }

    func fetchByMonth(_ date: Date) throws -> [Transaction] {
        // TODO: Implement — filter to calendar month containing date
        []
    }

    func add(_ transaction: Transaction) throws {
        // TODO: Implement — insert into context and save
    }

    func update(_ transaction: Transaction) throws {
        // TODO: Implement — save context after external mutation
    }

    func delete(_ transaction: Transaction) throws {
        // TODO: Implement — delete from context and save
    }
}
