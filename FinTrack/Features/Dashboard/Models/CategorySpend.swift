import Foundation

struct CategorySpend: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let icon: String
    let amount: Double
    let percentage: Double  // fraction of total expense (0.0–1.0)
}
