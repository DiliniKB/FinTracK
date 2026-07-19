import Foundation

struct ParsedSMSResult {
    let amount: Double              // always in LKR (converted if foreign)
    let originalAmount: Double      // raw parsed amount in original currency
    let originalCurrency: String    // "LKR", "USD", "SGD", etc.
    let type: CategoryType
    let payee: String
    let date: Date
    let suggestedCategoryId: UUID?
    let rawSMS: String
    let bank: DetectedBank
    let confidence: Double

    var isForeignCurrency: Bool { originalCurrency != "LKR" }
}
