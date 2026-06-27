import Foundation

/// Reads build-time configuration values injected by Config.xcconfig
/// via the app target's Info.plist.
///
/// To wire a new key:
///   1. Add `KEY = value` to Config.xcconfig
///   2. Add `$(KEY)` to Info.plist under the same key name
///   3. Expose it here as a static property
enum AppConfig {

    /// Google OAuth client ID — sourced from GOOGLE_CLIENT_ID in Config.xcconfig.
    static let googleClientID: String = infoPlistValue(for: "GOOGLE_CLIENT_ID")

    // MARK: - Helpers

    private static func infoPlistValue(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty
        else {
            fatalError("AppConfig: '\(key)' is missing or empty in Info.plist. Check Config.xcconfig is linked to the active scheme.")
        }
        return value
    }
}
