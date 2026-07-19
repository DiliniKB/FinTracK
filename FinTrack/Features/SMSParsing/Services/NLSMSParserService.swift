import Foundation
import NaturalLanguage

final class NLSMSParserService: SMSParserService {

    func parse(_ text: String, sender: String? = nil) throws -> ParsedSMSResult {
        guard isBankSMS(text) else { throw SMSParseError.notBankSMS }

        let bank        = detectBank(text, sender: sender)
        let amount      = try extractAmount(text)
        let currency    = extractCurrency(text)
        let type        = detectType(text)
        let payee       = extractPayee(text, bank: bank)
        let rawDate     = extractDate(text)

        return ParsedSMSResult(
            amount:              amount,
            originalAmount:      amount,
            originalCurrency:    currency,
            type:                type,
            payee:               payee,
            date:                rawDate ?? Date(),
            suggestedCategoryId: nil,
            rawSMS:              text,
            bank:                bank,
            confidence:          computeConfidence(amount: amount, payee: payee, dateFound: rawDate != nil)
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
        // Check debit first — "credit card debited" should still be expense
        let debitKeywords = ["debited", "debit card", "withdrawn", "purchase", "authorised", "authorized"]
        if debitKeywords.contains(where: { lower.contains($0) }) { return .expense }
        let creditKeywords = ["credited", "received", "deposited", "added"]
        return creditKeywords.contains(where: { lower.contains($0) }) ? .income : .expense
    }

    // MARK: - Payee extraction

    private func extractPayee(_ text: String, bank: DetectedBank) -> String {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        // Collect (word, range) pairs tagged as organisation names
        var orgTokens: [(word: String, range: Range<String.Index>)] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            if tag == .organizationName {
                orgTokens.append((String(text[range]), range))
            }
            return true
        }

        // Join consecutive tokens (separated only by whitespace) into full merchant names
        var merged: [String] = []
        var currentGroup: [(word: String, range: Range<String.Index>)] = []
        for token in orgTokens {
            if let last = currentGroup.last {
                let gap = String(text[last.range.upperBound..<token.range.lowerBound])
                if gap.allSatisfy({ $0.isWhitespace }) {
                    currentGroup.append(token)
                    continue
                }
                merged.append(currentGroup.map(\.word).joined(separator: " "))
            }
            currentGroup = [token]
        }
        if !currentGroup.isEmpty {
            merged.append(currentGroup.map(\.word).joined(separator: " "))
        }

        let bankNames = ["COMBANK", "SAMPATH", "HNB", "BOC", "NSB", "PEOPLESB",
                         "Commercial", "Sampath", "Peoples"]
        if let merchant = merged.first(where: { org in
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
        // Try numeric date formats first (DD/MM/YY, DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY).
        // NSDataDetector misreads "17/07/26" as YY/MM/DD → 2017 instead of DD/MM/YY → 2026.
        let numericPattern = #"(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})"#
        if let regex = try? NSRegularExpression(pattern: numericPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let r1 = Range(match.range(at: 1), in: text),
           let r2 = Range(match.range(at: 2), in: text),
           let r3 = Range(match.range(at: 3), in: text),
           let day   = Int(text[r1]),
           let month = Int(text[r2]),
           let rawYear = Int(text[r3]),
           day >= 1, day <= 31, month >= 1, month <= 12 {
            let year = rawYear < 100 ? 2000 + rawYear : rawYear
            var components = DateComponents()
            components.day   = day
            components.month = month
            components.year  = year
            if let date = Calendar.current.date(from: components) { return date }
        }

        // Try "DD-MMM-YYYY" style (e.g., "27-Jun-2026", "17-Jul-2026")
        let namedMonthPattern = #"(\d{1,2})[/\-\s]([A-Za-z]{3,9})[/\-\s,\s](\d{2,4})"#
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        for fmt in ["d-MMM-yyyy", "d MMM yyyy", "d/MMM/yyyy", "d-MMMM-yyyy", "d MMMM yyyy"] {
            formatter.dateFormat = fmt
            if let regex = try? NSRegularExpression(pattern: namedMonthPattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 0), in: text) {
                let candidate = String(text[range])
                if let date = formatter.date(from: candidate) { return date }
            }
        }

        // Last resort: NSDataDetector (handles long-form dates like "July 17, 2026")
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).first?.date
    }

    // MARK: - Confidence score

    private func computeConfidence(amount: Double, payee: String, dateFound: Bool) -> Double {
        var score = 0.0
        if amount > 0                  { score += 0.5 }
        if payee != "Unknown Merchant" { score += 0.3 }
        if dateFound                   { score += 0.2 }
        return score
    }
}
