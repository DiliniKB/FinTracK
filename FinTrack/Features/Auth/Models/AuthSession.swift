import Foundation

/// Represents an active local authentication session.
/// Persisted in Keychain under `fintrack.auth.session`.
/// V2: will gain `accessToken` and `refreshToken` fields.
struct AuthSession: Codable {
    let userId: String
    let provider: AuthProvider
    let createdAt: Date
}
