import Foundation
import SwiftData

/// Persistent category model stored via SwiftData.
/// System-seeded defaults have `isDefault == true` and cannot be edited or deleted.
@Model
final class Category {

    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String          // SF Symbol name e.g. "fork.knife"
    var colorHex: String      // Hex string e.g. "#FF6B6B"
    var type: CategoryType    // .income / .expense
    var isDefault: Bool       // true = system default, cannot be edited/deleted
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        type: CategoryType,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        // TODO: Assign all properties
        self.id        = id
        self.name      = name
        self.icon      = icon
        self.colorHex  = colorHex
        self.type      = type
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}
