import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var type: CategoryType
    var categoryId: UUID
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var payee: String
    var note: String
    var date: Date
    var createdAt: Date
    var source: TransactionSource

    init(
        id: UUID = UUID(),
        amount: Double,
        type: CategoryType,
        categoryId: UUID,
        categoryName: String,
        categoryIcon: String,
        categoryColorHex: String,
        payee: String = "",
        note: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        source: TransactionSource = .manual
    ) {
        // TODO: Implement initializer
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.categoryColorHex = categoryColorHex
        self.payee = payee
        self.note = note
        self.date = date
        self.createdAt = createdAt
        self.source = source
    }
}
