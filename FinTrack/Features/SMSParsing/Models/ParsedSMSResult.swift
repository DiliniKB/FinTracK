import Foundation

struct ParsedSMSResult {
    let amount: Double
    let type: CategoryType
    let payee: String
    let date: Date
    let suggestedCategoryId: UUID?
    let rawSMS: String
    let bank: DetectedBank
    let confidence: Double
}
