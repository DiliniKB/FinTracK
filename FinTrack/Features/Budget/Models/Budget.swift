import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var limitAmount: Double
    var month: Date           // Always normalized to first day of month
    var alertFired: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        categoryName: String,
        categoryIcon: String,
        categoryColorHex: String,
        limitAmount: Double,
        month: Date,
        alertFired: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id               = id
        self.categoryId       = categoryId
        self.categoryName     = categoryName
        self.categoryIcon     = categoryIcon
        self.categoryColorHex = categoryColorHex
        self.limitAmount      = limitAmount
        self.month            = month
        self.alertFired       = alertFired
        self.createdAt        = createdAt
    }
}
