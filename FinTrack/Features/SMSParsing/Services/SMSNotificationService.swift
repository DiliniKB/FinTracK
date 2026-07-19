import Foundation
import UserNotifications

final class SMSNotificationService {

    func requestPermissionIfNeeded() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func notifyParsed(_ result: ParsedSMSResult) async {
        let content       = UNMutableNotificationContent()
        content.title     = "New Transaction Detected"
        content.body      = "\(result.type == .expense ? "Expense" : "Income") of \(formatted(result.amount)) from \(result.payee)"
        content.sound     = .default
        content.userInfo  = ["action": "confirm_sms"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sms-parsed-\(UUID().uuidString)",
            content:    content,
            trigger:    trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func formatted(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "Rs. \(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}
