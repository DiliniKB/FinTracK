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
    private let currencyConverter:   CurrencyConverterService

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
        categoryRepository:  any CategoryRepository,
        currencyConverter:   CurrencyConverterService = CurrencyConverterService()
    ) {
        self.parser              = parser
        self.notificationService = notificationService
        self.categoryRepository  = categoryRepository
        self.currencyConverter   = currencyConverter
    }

    // MARK: - Notification permission

    func requestNotificationPermission() async {
        await notificationService.requestPermissionIfNeeded()
    }

    // MARK: - Handle incoming SMS

    func handle(smsText: String, sender: String? = nil) {
        parseError = nil
        Task {
            do {
                var result = try parser.parse(smsText, sender: sender)
                result = await convertToLKR(result)
                result = resolveCategoryId(for: result)
                pendingResult    = result
                showConfirmation = true
                await notificationService.notifyParsed(result)
            } catch let error as SMSParseError {
                parseError = error
            } catch {
                parseError = .parseFailure(error.localizedDescription)
            }
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

    // MARK: - Currency conversion

    private func convertToLKR(_ result: ParsedSMSResult) async -> ParsedSMSResult {
        guard result.isForeignCurrency else { return result }
        let lkrAmount = await currencyConverter.convertToLKR(
            amount: result.originalAmount,
            from:   result.originalCurrency
        )
        return ParsedSMSResult(
            amount:              lkrAmount ?? result.originalAmount, // fallback: raw amount, user corrects in sheet
            originalAmount:      result.originalAmount,
            originalCurrency:    result.originalCurrency,
            type:                result.type,
            payee:               result.payee,
            date:                result.date,
            suggestedCategoryId: result.suggestedCategoryId,
            rawSMS:              result.rawSMS,
            bank:                result.bank,
            confidence:          lkrAmount != nil ? result.confidence : result.confidence * 0.7
        )
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
            originalAmount:      result.originalAmount,
            originalCurrency:    result.originalCurrency,
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
