# SMS Parsing Module Spec — V1
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
Automatically parse incoming bank SMS messages from Sri Lankan banks using NaturalLanguage framework, extract transaction details, and prompt the user to confirm before saving. Triggered via iOS Shortcuts automation + URL scheme.

### Scope
- URL scheme handler: `fintrack://sms?text=...`
- NaturalLanguage-based parsing pipeline
- Regex fallback patterns per SL bank
- Parsed result confirmation screen
- Auto-creates Transaction with `source: .sms`
- Local notification → user taps → opens confirmation screen

### Out of Scope
- Background SMS monitoring
- iMessage parsing
- Multi-SMS threading

---

## 2. Supported Banks & Patterns

| Bank | Sender ID | Sample SMS |
|---|---|---|
| Commercial Bank | COMBANK | `Your A/C 1234 debited Rs.5,000.00 at KEELLS on 27-06-2026` |
| Sampath Bank | SAMPATH | `Rs.3,500.00 debited from A/C **5678 at ARPICO 27/06/2026` |
| HNB | HNB | `HNB: Rs.1,200.00 has been debited from your account 9012 on 27-Jun-2026` |
| BOC | BOCLK | `BOC: Debit Rs.800.00 A/C 3456 Merchant: CARGILLS 27.06.2026` |
| NSB | NSBLK | `NSB Alert: Rs.2,000.00 withdrawn from A/C 7890 at ATM 27-06-2026` |
| People's Bank | PEOPLESB | `Peoples Bank: A/C 2345 debited by Rs.4,500.00 for KEELLS on 27-06-2026` |

---

## 3. Parsing Pipeline

```
Raw SMS Text
    ↓
1. BankDetector          → identifies bank from sender/content keywords
    ↓
2. NLTokenizer           → tokenizes SMS into words/numbers
    ↓
3. NLTagger              → tags tokens (number, currency, date, organization)
    ↓
4. AmountExtractor       → finds Rs./LKR amount
    ↓
5. TypeDetector          → debit/credit keywords → .expense / .income
    ↓
6. MerchantExtractor     → extracts merchant/payee name
    ↓
7. DateExtractor         → extracts transaction date (fallback: today)
    ↓
8. CategorySuggester     → maps merchant keywords to category
    ↓
ParsedSMSResult or ParseError
```

---

## 4. Data Models

```swift
struct ParsedSMSResult {
    let amount: Double              // always in LKR (converted if foreign)
    let originalAmount: Double      // raw parsed amount in original currency
    let originalCurrency: String    // "LKR", "USD", "SGD", etc.
    let type: CategoryType          // .income / .expense
    let payee: String               // merchant name
    let date: Date
    let suggestedCategoryId: UUID?  // nil if no match found
    let rawSMS: String              // original text for audit
    let bank: DetectedBank
    let confidence: Double          // 0.0–1.0

    var isForeignCurrency: Bool { originalCurrency != "LKR" }
}

enum DetectedBank: String, CaseIterable {
    case commercial = "Commercial Bank"
    case sampath    = "Sampath Bank"
    case hnb        = "HNB"
    case boc        = "BOC"
    case nsb        = "NSB"
    case peoples    = "People's Bank"
    case unknown    = "Unknown"
}

enum SMSParseError: LocalizedError {
    case notBankSMS
    case amountNotFound
    case ambiguousAmount
    case parseFailure(String)
}
```

---

## 5. URL Scheme Handler

### Registration (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fintrack</string>
        </array>
    </dict>
</array>
```

### Handler (in AppRootView.swift)
```swift
// URL format: fintrack://sms?sender=COMBANK&text=<message body>
// Note: '#' in SMS body is handled defensively by re-attaching the URL fragment.
.onOpenURL { url in
    guard url.scheme == "fintrack", url.host == "sms" else { return }
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    if let fragment = url.fragment {
        if let idx = components?.queryItems?.firstIndex(where: { $0.name == "text" }) {
            let existing = components?.queryItems?[idx].value ?? ""
            components?.queryItems?[idx] = URLQueryItem(name: "text", value: existing + "#" + fragment)
        }
    }
    guard let smsText = components?.queryItems?.first(where: { $0.name == "text" })?.value
    else { return }
    let sender = components?.queryItems?.first(where: { $0.name == "sender" })?.value
    smsCoordinator?.handle(smsText: smsText, sender: sender)
}
```

### Shortcut URL format
```
fintrack://sms?sender=[Shortcut Input → Sender Name]&text=[Shortcut Input → Message Content]
```

---

## 6. SMS Coordinator

```swift
@Observable
@MainActor
final class SMSCoordinator {
    var pendingResult: ParsedSMSResult? = nil
    var showConfirmation: Bool = false
    var parseError: SMSParseError? = nil

    private let parser: SMSParserService
    private let notificationService: SMSNotificationService

    func handle(smsText: String) {
        do {
            let result = try parser.parse(smsText)
            pendingResult = result
            // Fire local notification
            Task { await notificationService.notifyParsed(result) }
            // If app is foregrounded, show confirmation directly
            showConfirmation = true
        } catch {
            parseError = error as? SMSParseError
        }
    }
}
```

---

## 7. SMS Parser Service

```swift
protocol SMSParserService {
    func parse(_ text: String) throws -> ParsedSMSResult
}

final class NLSMSParserService: SMSParserService {

    func parse(_ text: String) throws -> ParsedSMSResult {
        guard isBankSMS(text) else { throw SMSParseError.notBankSMS }

        let bank     = detectBank(text)
        let amount   = try extractAmount(text)
        let type     = detectType(text)
        let payee    = extractPayee(text, bank: bank)
        let date     = extractDate(text) ?? Date()
        let category = suggestCategory(for: payee)

        return ParsedSMSResult(
            amount:              amount,
            type:                type,
            payee:               payee,
            date:                date,
            suggestedCategoryId: category?.id,
            rawSMS:              text,
            bank:                bank,
            confidence:          computeConfidence(amount: amount, payee: payee, date: date)
        )
    }

    // MARK: - NL Pipeline steps

    private func isBankSMS(_ text: String) -> Bool {
        // Check for bank keywords + debit/credit keywords
        let bankKeywords = ["debited", "debit", "credited", "credit", "withdrawn",
                           "COMBANK", "SAMPATH", "HNB", "BOC", "NSB", "PEOPLESB",
                           "A/C", "account"]
        let lower = text.lowercased()
        return bankKeywords.contains { lower.contains($0.lowercased()) }
    }

    private func detectBank(_ text: String) -> DetectedBank {
        if text.contains("COMBANK") || text.contains("Commercial") { return .commercial }
        if text.contains("SAMPATH") || text.contains("Sampath")    { return .sampath }
        if text.contains("HNB")                                     { return .hnb }
        if text.contains("BOCLK") || text.contains("BOC:")         { return .boc }
        if text.contains("NSBLK") || text.contains("NSB Alert")    { return .nsb }
        if text.contains("PEOPLESB") || text.contains("Peoples")   { return .peoples }
        return .unknown
    }

    private func extractAmount(_ text: String) throws -> Double {
        // Use NLTokenizer to find numeric tokens near Rs./LKR
        // Regex fallback: Rs\.[\d,]+\.?\d*
        let pattern = #"(?:Rs\.?|LKR)\s*([\d,]+(?:\.\d{1,2})?)"#
        guard let regex   = try? NSRegularExpression(pattern: pattern),
              let match   = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range   = Range(match.range(at: 1), in: text)
        else { throw SMSParseError.amountNotFound }

        let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
        guard let amount = Double(amountString) else { throw SMSParseError.amountNotFound }
        return amount
    }

    private func detectType(_ text: String) -> CategoryType {
        let lower = text.lowercased()
        let creditKeywords = ["credited", "credit", "received", "deposited", "added"]
        return creditKeywords.contains(where: { lower.contains($0) }) ? .income : .expense
    }

    private func extractPayee(_ text: String, bank: DetectedBank) -> String {
        // Use NLTagger with .nameOrganization to find merchant name
        // Fallback: parse "at MERCHANT" or "Merchant: MERCHANT" patterns
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var organizations: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType) { tag, range in
            if tag == .organizationName {
                organizations.append(String(text[range]))
            }
            return true
        }
        // Filter out bank names from results
        let bankNames = ["COMBANK", "SAMPATH", "HNB", "BOC", "NSB", "PEOPLESB",
                        "Commercial", "Sampath", "Peoples"]
        let merchant = organizations.first { org in
            !bankNames.contains(where: { org.contains($0) })
        }
        return merchant ?? extractPayeeFallback(text)
    }

    private func extractPayeeFallback(_ text: String) -> String {
        // Pattern: "at MERCHANT" or "Merchant: MERCHANT" or "for MERCHANT"
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

    private func extractDate(_ text: String) -> Date? {
        // NLDataDetector for dates
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches  = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches?.first?.date
    }

    private func suggestCategory(for payee: String) -> Category? {
        // Keyword → category mapping
        // Returns nil if no confident match — user picks manually in confirmation
        nil // wired up in ViewModel which has CategoryRepository access
    }

    private func computeConfidence(amount: Double, payee: String, date: Date?) -> Double {
        var score = 0.0
        if amount > 0                          { score += 0.5 }
        if payee != "Unknown Merchant"         { score += 0.3 }
        if date != nil                         { score += 0.2 }
        return score
    }
}
```

---

## 8. Category Suggestion Mapping

```swift
// In SMSCoordinator or BudgetViewModel — has CategoryRepository access
let merchantKeywords: [String: String] = [
    // keyword → category name (case-insensitive match)
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
```

---

## 9. Notification Flow

```swift
final class SMSNotificationService {
    func notifyParsed(_ result: ParsedSMSResult) async {
        let content = UNMutableNotificationContent()
        content.title = "New Transaction Detected"
        content.body  = "\(result.type == .expense ? "Expense" : "Income") of \(formatted(result.amount)) from \(result.payee)"
        content.sound = .default
        content.userInfo = ["action": "confirm_sms"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sms-parsed-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
```

User taps notification → app opens → `SMSCoordinator.showConfirmation = true` → `SMSConfirmationSheet` appears.

---

## 10. Confirmation Screen

```swift
struct SMSConfirmationSheet: View {
    // Shows parsed result:
    // - Bank name + confidence indicator
    // - Amount (editable)
    // - Type toggle
    // - Category picker (pre-selected if suggestedCategoryId matched)
    // - Payee (editable)
    // - Date (editable)
    // - Raw SMS text (collapsed, expandable)
    // Buttons: "Save Transaction" / "Discard"
}
```

On Save → creates `Transaction` with `source: .sms` → dismisses sheet.

---

## 11. Shortcuts Setup (User Guide — in app onboarding)

```
1. Open Shortcuts app
2. Create new automation: "When I receive a message from COMBANK / SAMPATH / HNB..."
3. Add action: "Open URL"
4. URL: fintrack://sms?text=[Shortcut Input > Message Content]
5. Disable "Ask Before Running"
```

---

## 12. File Structure

```
Features/SMSParsing/
├── Models/
│   ├── ParsedSMSResult.swift
│   ├── DetectedBank.swift
│   └── SMSParseError.swift
├── Services/
│   ├── SMSParserService.swift          # Protocol (V2 swap point for Claude API)
│   ├── NLSMSParserService.swift        # NL implementation
│   ├── SMSNotificationService.swift    # UNUserNotificationCenter
│   └── CurrencyConverterService.swift  # Converts foreign currency to LKR via open.er-api.com
├── Coordinator/
│   └── SMSCoordinator.swift            # Owns pending state, wires parser + notification + conversion
└── Views/
    └── SMSConfirmationSheet.swift      # Editable confirmation before save
```

---

## 13. Acceptance Criteria

- [ ] `fintrack://sms?sender=BANK&text=...` URL scheme opens app and triggers parsing
- [ ] Amount extracted correctly from all 6 bank formats
- [ ] Foreign currency amounts (USD, SGD, EUR, GBP, AUD) converted to LKR via live rate
- [ ] Debit keywords take priority over credit keywords in type detection
- [ ] Multi-word merchant names extracted correctly (e.g. "KEELLS SUPER")
- [ ] Bank detected from sender ID first, then SMS body; editable in confirmation sheet
- [ ] Date extracted (fallback to today); confidence reflects whether date was found
- [ ] `#` in SMS body handled correctly (URL fragment reattachment)
- [ ] Rapid SMS handled without race condition (in-flight parse cancelled on new SMS)
- [ ] Local notification fires with amount + payee
- [ ] Tapping notification opens confirmation sheet
- [ ] User can edit all fields before saving
- [ ] Category pre-selected if merchant keyword matched
- [ ] Saved transaction has `source: .sms` and `bank` set
- [ ] Non-bank SMS silently ignored (no notification)

---

## 14. V2 Notes
- Replace NL pipeline with Claude API for smarter extraction
- Support more banks as patterns are contributed
- Batch SMS import from Messages app
- Confidence score shown to user in confirmation sheet
