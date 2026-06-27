import Foundation

protocol BudgetRepository {
    func fetchAll() throws -> [Budget]
    func fetchByMonth(_ date: Date) throws -> [Budget]
    func fetchByCategory(_ categoryId: UUID, month: Date) throws -> Budget?
    func add(_ budget: Budget) throws
    func update(_ budget: Budget) throws
    func delete(_ budget: Budget) throws
}
