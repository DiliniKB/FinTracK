import Foundation

final class CurrencyConverterService {

    // Fetches live rate from frankfurter.app (free, no API key).
    // Returns the amount converted to LKR, or nil if offline / unsupported currency.
    func convertToLKR(amount: Double, from currency: String) async -> Double? {
        guard currency != "LKR" else { return amount }

        // open.er-api.com: free, no API key, supports LKR
        let urlString = "https://open.er-api.com/v6/latest/\(currency)"
        guard let url = URL(string: urlString) else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Double],
              let rate = rates["LKR"]
        else { return nil }

        return amount * rate
    }
}
