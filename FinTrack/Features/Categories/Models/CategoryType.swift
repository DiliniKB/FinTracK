import Foundation

/// Classifies a category as income-producing or expense-generating.
enum CategoryType: String, Codable, CaseIterable {
    case income
    case expense

    var displayName: String {
        // TODO: Return localised display label ("Income" / "Expense")
        rawValue.capitalized
    }
}
