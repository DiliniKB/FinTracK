import Foundation
import Security

// MARK: - Error

enum KeychainError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to JSON-encode value for Keychain."
        case .decodingFailed:
            return "Failed to JSON-decode value from Keychain."
        case .unexpectedStatus(let status):
            return "Keychain operation failed with OSStatus \(status)."
        }
    }
}

// MARK: - Keys

/// Keychain keys used by the auth module.
enum KeychainKey {
    static let session = "fintrack.auth.session"
    static let user    = "fintrack.auth.user"
}

// MARK: - Protocol

/// Abstracts Keychain read/write/delete operations.
protocol KeychainService {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func read<T: Codable>(forKey key: String) throws -> T?
    func delete(forKey key: String) throws
}

// MARK: - Default Implementation

/// Concrete Keychain implementation using the Security framework.
/// Items are stored as generic passwords (`kSecClassGenericPassword`)
/// scoped to the app's bundle ID (`kSecAttrService`).
final class DefaultKeychainService: KeychainService {

    private let service: String

    /// - Parameter service: The Keychain service name used to namespace items.
    ///   Defaults to the app's bundle identifier.
    init(service: String = Bundle.main.bundleIdentifier ?? "com.fintrack.app") {
        self.service = service
    }

    // MARK: - Save

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try encode(value)

        // Remove any pre-existing item first (upsert pattern).
        // Ignore errSecItemNotFound — it just means there was nothing to delete.
        let deleteQuery = baseQuery(for: key)
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(deleteStatus)
        }

        var addQuery = baseQuery(for: key)
        addQuery[kSecValueData as String] = data
        // Make the item accessible when the device is unlocked.
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }

    // MARK: - Read

    func read<T: Codable>(forKey key: String) throws -> T? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.decodingFailed
            }
            return try decode(T.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Delete

    func delete(forKey key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Helpers

    /// Builds the base attribute dictionary shared by all Keychain queries.
    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    private func encode<T: Codable>(_ value: T) throws -> Data {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            throw KeychainError.encodingFailed
        }
    }

    private func decode<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw KeychainError.decodingFailed
        }
    }
}
