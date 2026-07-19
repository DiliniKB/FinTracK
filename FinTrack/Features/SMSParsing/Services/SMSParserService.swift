import Foundation

protocol SMSParserService {
    func parse(_ text: String) throws -> ParsedSMSResult
}
