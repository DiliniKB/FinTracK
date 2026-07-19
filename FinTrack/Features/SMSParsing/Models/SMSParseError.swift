import Foundation

enum SMSParseError: LocalizedError {
    case notBankSMS
    case amountNotFound
    case ambiguousAmount
    case parseFailure(String)

    var errorDescription: String? {
        switch self {
        case .notBankSMS:               return "Message does not appear to be a bank SMS."
        case .amountNotFound:           return "Could not extract a transaction amount."
        case .ambiguousAmount:          return "Multiple amounts found — unable to determine which is the transaction."
        case .parseFailure(let detail): return "Parse failed: \(detail)"
        }
    }
}
