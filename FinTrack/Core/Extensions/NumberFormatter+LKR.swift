import Foundation

extension NumberFormatter {
    static let lkr: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "LKR"
        f.currencySymbol = "Rs."
        f.maximumFractionDigits = 2
        return f
    }()
}
