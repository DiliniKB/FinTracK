import Foundation

protocol TransactionRepository {
    func fetchAll() throws -> [Transaction]
    func fetchByType(_ type: CategoryType) throws -> [Transaction]
    func fetchByMonth(_ date: Date) throws -> [Transaction]
    func add(_ transaction: Transaction) throws
    func update(_ transaction: Transaction) throws
    func delete(_ transaction: Transaction) throws
}
