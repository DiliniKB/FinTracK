import Foundation

/// Represents an authenticated local user profile.
/// Persisted in Keychain under `fintrack.auth.user`.
struct User: Codable {
    let id: String           // IDP-provided unique ID
    let name: String
    let email: String
    let provider: AuthProvider
    let createdAt: Date
}
