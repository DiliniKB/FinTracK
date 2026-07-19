import Foundation
import Observation

@Observable
@MainActor
final class SMSCoordinator {

    // MARK: - State

    private(set) var pendingResult: ParsedSMSResult? = nil
    var showConfirmation: Bool = false
    private(set) var parseError: SMSParseError? = nil

    // MARK: - Dependencies

    private let parser:              any SMSParserService
    private let notificationService: SMSNotificationService
    private let categoryRepository:  any CategoryRepository

    // MARK: - Category suggestion map (merchant keyword → category name)

    private let merchantKeywords: [String: String] = [
        "keells":      "Food & Dining",
        "cargills":    "Food & Dining",
        "arpico":      "Shopping",
        "supermarket": "Food & Dining",
        "pharmacy":    "Health",
        "hospital":    "Health",
        "uber":        "Transport",
        "pickme":      "Transport",
        "fuel":        "Transport",
        "electricity": "Utilities",
        "water":       "Utilities",
        "dialog":      "Utilities",
        "mobitel":     "Utilities",
        "airtel":      "Utilities",
        "amazon":      "Shopping",
    ]

    // MARK: - Init

    init(
        parser:              any SMSParserService,
        notificationService: SMSNotificationService,
        categoryRepository:  any CategoryRepository
    ) {
        self.parser              = parser
        self.notificationService = notificationService
        self.categoryRepository  = categoryRepository
    }

    // MARK: - Notification permission

    func requestNotificationPermission() async {
        await notificationService.requestPermissionIfNeeded()
    }

    // MARK: - Handle incoming SMS

    func handle(smsText: String) {
        parseError = nil
        do {
            var result = try parser.parse(smsText)
            result = resolveCategoryId(for: result)
            pendingResult    = result
            showConfirmation = true
            Task { await notificationService.notifyParsed(result) }
        } catch let error as SMSParseError {
            parseError = error
        } catch {
            parseError = .parseFailure(error.localizedDescription)
        }
    }

    // MARK: - Save confirmed transaction

    func confirmAndSave(
        amount:     Double,
        type:       CategoryType,
        category:   Category,
        payee:      String,
        date:       Date,
        repository: any TransactionRepository
    ) throws {
        let transaction = Transaction(
            amount:           amount,
            type:             type,
            categoryId:       category.id,
            categoryName:     category.name,
            categoryIcon:     category.icon,
            categoryColorHex: category.colorHex,
            payee:            payee,
            date:             date,
            source:           .sms
        )
        try repository.add(transaction)
        dismiss()
    }

    // MARK: - Dismiss without saving

    func dismiss() {
        pendingResult    = nil
        showConfirmation = false
        parseError       = nil
    }

    // MARK: - Category suggestion

    private func resolveCategoryId(for result: ParsedSMSResult) -> ParsedSMSResult {
        let payeeLower = result.payee.lowercased()
        guard let matchedName = merchantKeywords.first(where: { payeeLower.contains($0.key) })?.value,
              let categories  = try? categoryRepository.fetchByType(result.type),
              let match       = categories.first(where: { $0.name.lowercased() == matchedName.lowercased() })
        else { return result }

        return ParsedSMSResult(
            amount:              result.amount,
            type:                result.type,
            payee:               result.payee,
            date:                result.date,
            suggestedCategoryId: match.id,
            rawSMS:              result.rawSMS,
            bank:                result.bank,
            confidence:          result.confidence
        )
    }
}
