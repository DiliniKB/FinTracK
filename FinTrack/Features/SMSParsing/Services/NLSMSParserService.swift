import Foundation
import NaturalLanguage

final class NLSMSParserService: SMSParserService {

    func parse(_ text: String) throws -> ParsedSMSResult {
        guard isBankSMS(text) else { throw SMSParseError.notBankSMS }

        let bank   = detectBank(text)
        let amount = try extractAmount(text)
        let type   = detectType(text)
        let payee  = extractPayee(text, bank: bank)
        let date   = extractDate(text) ?? Date()

        return ParsedSMSResult(
            amount:              amount,
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
                        "A/C", "account"]
        let lower = text.lowercased()
        return keywords.contains { lower.contains($0.lowercased()) }
    }

    private func detectBank(_ text: String) -> DetectedBank {
        if text.contains("COMBANK") || text.contains("Commercial") { return .commercial }
        if text.contains("SAMPATH") || text.contains("Sampath")    { return .sampath }
        if text.contains("HNB")                                     { return .hnb }
        if text.contains("BOCLK")  || text.contains("BOC:")        { return .boc }
        if text.contains("NSBLK")  || text.contains("NSB Alert")   { return .nsb }
        if text.contains("PEOPLESB") || text.contains("Peoples")   { return .peoples }
        return .unknown
    }

    // MARK: - Amount extraction

    private func extractAmount(_ text: String) throws -> Double {
        let pattern = #"(?:Rs\.?|LKR)\s*([\d,]+(?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { throw SMSParseError.amountNotFound }

        let raw = String(text[range]).replacingOccurrences(of: ",", with: "")
        guard let amount = Double(raw) else { throw SMSParseError.amountNotFound }
        return amount
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
