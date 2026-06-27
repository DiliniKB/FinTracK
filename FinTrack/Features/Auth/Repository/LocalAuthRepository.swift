import AuthenticationServices
import GoogleSignIn

// MARK: - Error

enum LocalAuthError: LocalizedError {
    /// Apple omits the user's name and email on every sign-in after the first.
    /// This is thrown only when there is no cached user in Keychain to fall back to.
    case appleEmailMissing
    case googleProfileMissing
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .appleEmailMissing:
            return "Apple did not provide an email and no cached user was found. Please sign out of Apple ID in Settings and try again."
        case .googleProfileMissing:
            return "Google sign-in succeeded but the user profile was incomplete."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Repository

/// V1 implementation of `AuthRepository`.
/// All data is stored locally in the Keychain — no backend calls.
/// V2: swap for `RemoteAuthRepository` conforming to the same protocol.
final class LocalAuthRepository: AuthRepository {

    private let keychainService: any KeychainService

    init(keychainService: any KeychainService) {
        self.keychainService = keychainService
    }

    // MARK: - Sign in with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        // Apple only provides fullName and email on the *first* authorisation.
        // On subsequent sign-ins both are nil. Fall back to the cached user's
        // email/name so we can still construct a valid User.
        let cachedUser: User? = try? keychainService.read(forKey: KeychainKey.user)

        let name: String = {
            if let given  = credential.fullName?.givenName,
               let family = credential.fullName?.familyName {
                return "\(given) \(family)".trimmingCharacters(in: .whitespaces)
            }
            return cachedUser?.name ?? ""
        }()

        guard let email = credential.email ?? cachedUser?.email else {
            throw LocalAuthError.appleEmailMissing
        }

        let user = User(
            id:        credential.user,   // stable IDP-provided identifier
            name:      name,
            email:     email,
            provider:  .apple,
            createdAt: cachedUser?.createdAt ?? Date()   // preserve original join date on re-auth
        )

        let session = AuthSession(
            userId:    user.id,
            provider:  .apple,
            createdAt: Date()
        )

        try keychainService.save(user,    forKey: KeychainKey.user)
        try keychainService.save(session, forKey: KeychainKey.session)

        return user
    }

    // MARK: - Sign in with Google

    func signInWithGoogle(credential: GIDGoogleUser) async throws -> User {
        guard
            let profile = credential.profile,
            !profile.email.isEmpty
        else {
            throw LocalAuthError.googleProfileMissing
        }

        let cachedUser: User? = try? keychainService.read(forKey: KeychainKey.user)

        let user = User(
            id:        credential.userID ?? UUID().uuidString,
            name:      profile.name,
            email:     profile.email,
            provider:  .google,
            createdAt: cachedUser?.createdAt ?? Date()
        )

        let session = AuthSession(
            userId:    user.id,
            provider:  .google,
            createdAt: Date()
        )

        try keychainService.save(user,    forKey: KeychainKey.user)
        try keychainService.save(session, forKey: KeychainKey.session)

        return user
    }

    // MARK: - Read

    func getCurrentUser() -> User? {
        // Keychain failures are treated as unauthenticated (spec §11).
        // The error is silently swallowed here; callers needing the raw error
        // can be extended in V2 when backend error reporting is added.
        try? keychainService.read(forKey: KeychainKey.user)
    }

    func getSession() -> AuthSession? {
        try? keychainService.read(forKey: KeychainKey.session)
    }

    // MARK: - Sign Out

    func signOut() throws {
        // Delete both entries. If one is missing that's fine — KeychainService.delete
        // ignores errSecItemNotFound, so signOut is always idempotent.
        try keychainService.delete(forKey: KeychainKey.session)
        try keychainService.delete(forKey: KeychainKey.user)
    }
}
