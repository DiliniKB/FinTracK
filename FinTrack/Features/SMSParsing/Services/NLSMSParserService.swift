import Foundation
import NaturalLanguage

final class NLSMSParserService: SMSParserService {

    func parse(_ text: String, sender: String? = nil) throws -> ParsedSMSResult {
        guard isBankSMS(text) else { throw SMSParseError.notBankSMS }

        let bank     = detectBank(text, sender: sender)
        let amount   = try extractAmount(text)
        let currency = extractCurrency(text)
        let type     = detectType(text)
        let payee    = extractPayee(text, bank: bank)
        let date     = extractDate(text) ?? Date()

        return ParsedSMSResult(
            amount:              amount, // converted to LKR by coordinator; raw value for now
            originalAmount:      amount,
            originalCurrency:    currency,
            type:                type,
            payee:               payee,
            date:                date,
            suggestedCategoryId: nil, // resolved by SMSCoordinator which has CategoryRepository
            rawSMS:              text,
            bank:                bank,
            confidence:          computeConfidence(amount: amount, payee: payee, date: date)
        )
    }

    // MARK: - Bank detection

    private func isBankSMS(_ text: String) -> Bool {
        let keywords = ["debited", "debit", "credited", "credit", "withdrawn",
                        "COMBANK", "SAMPATH", "HNB", "BOC", "NSB", "PEOPLESB",
                        "A/C", "account", "authorised", "authorized",
                        "debit card", "credit card", "cardholder", "purchase at"]
        let lower = text.lowercased()
        return keywords.contains { lower.contains($0.lowercased()) }
    }

    private func detectBank(_ text: String, sender: String? = nil) -> DetectedBank {
        // Check sender ID first — it's the most reliable signal
        let combined = [sender, text].compactMap { $0 }.joined(separator: " ")
        if combined.contains("COMBANK")  || combined.contains("Commercial") { return .commercial }
        if combined.contains("SAMPATH")  || combined.contains("Sampath")    { return .sampath }
        if combined.contains("HNB")                                          { return .hnb }
        if combined.contains("BOCLK")   || combined.contains("BOC:")        { return .boc }
        if combined.contains("NSBLK")   || combined.contains("NSB Alert")   { return .nsb }
        if combined.contains("PEOPLESB") || combined.contains("Peoples")    { return .peoples }
        return .unknown
    }

    // MARK: - Amount extraction

    private func extractAmount(_ text: String) throws -> Double {
        // Matches: Rs.5,000.00 / Rs 5000 / LKR 5000 / USD 3.29 / SGD 10.00 / EUR 5.00 etc.
        let pattern = #"(?:Rs\.?|LKR|USD|SGD|EUR|GBP|AUD)\s*([\d,]+(?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { throw SMSParseError.amountNotFound }

        let raw = String(text[range]).replacingOccurrences(of: ",", with: "")
        guard let amount = Double(raw) else { throw SMSParseError.amountNotFound }
        return amount
    }

    private func extractCurrency(_ text: String) -> String {
        let pattern = #"\b(Rs\.?|LKR|USD|SGD|EUR|GBP|AUD)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return "LKR" }
        let raw = String(text[range]).uppercased()
        return raw.hasPrefix("RS") ? "LKR" : raw
    }

    // MARK: - Type detection

    private func detectType(_ text: String) -> CategoryType {
        let lower = text.lowercased()
        let creditKeywords = ["credited", "credit", "received", "deposited", "added"]
        return creditKeywords.contains(where: { lower.contains($0) }) ? .income : .expense
    }

    // MARK: - Payee extraction

    private func extractPayee(_ text: String, bank: DetectedBank) -> String {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var organizations: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            if tag == .organizationName {
                organizations.append(String(text[range]))
            }
            return true
        }

        let bankNames = ["COMBANK", "SAMPATH", "HNB", "BOC", "NSB", "PEOPLESB",
                         "Commercial", "Sampath", "Peoples"]
        if let merchant = organizations.first(where: { org in
            !bankNames.contains(where: { org.contains($0) })
        }) {
            return merchant
        }
        return extractPayeeFallback(text)
    }

    private func extractPayeeFallback(_ text: String) -> String {
        let patterns = [
            #"(?:at|AT)\s+([A-Z][A-Z\s]{2,20})"#,
            #"[Mm]erchant:\s*([A-Z][A-Z\s]{2,20})"#,
            #"(?:for|FOR)\s+([A-Z][A-Z\s]{2,20})"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return "Unknown Merchant"
    }

    // MARK: - Date extraction

    private func extractDate(_ text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).first?.date
    }

    // MARK: - Confidence score

    private func computeConfidence(amount: Double, payee: String, date: Date?) -> Double {
        var score = 0.0
        if amount > 0                      { score += 0.5 }
        if payee != "Unknown Merchant"     { score += 0.3 }
        if date != nil                     { score += 0.2 }
        return score
    }
}
