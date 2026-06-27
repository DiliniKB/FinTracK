import Foundation

struct MonthlySummary {
    let month: Date
    let totalIncome: Double
    let totalExpense: Double

    var net: Double { totalIncome - totalExpense }
}
