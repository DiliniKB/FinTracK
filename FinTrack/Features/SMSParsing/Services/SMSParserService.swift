import Foundation

protocol SMSParserService {
    func parse(_ text: String, sender: String?) throws -> ParsedSMSResult
}
