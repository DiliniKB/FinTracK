import AuthenticationServices
// import GoogleSignIn   // Uncomment once SPM package is added

/// V1 implementation of `AuthRepository`.
/// All data is stored locally in the Keychain — no backend calls.
class LocalAuthRepository: AuthRepository {

    private let keychainService: any KeychainService

    init(keychainService: any KeychainService) {
        self.keychainService = keychainService
    }

    // MARK: - AuthRepository

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        // TODO: Extract name, email, userIdentifier from credential
        // TODO: Create User + AuthSession
        // TODO: Store both in Keychain via keychainService
        // TODO: Return the created User
        fatalError("Not implemented")
    }

    func signInWithGoogle(credential: Any) async throws -> User {
        // TODO: Cast credential to GIDGoogleUser once GoogleSignIn package is added
        // TODO: Extract profile (name, email, userID) from GIDGoogleUser
        // TODO: Create User + AuthSession
        // TODO: Store both in Keychain via keychainService
        // TODO: Return the created User
        fatalError("Not implemented")
    }

    func getCurrentUser() -> User? {
        // TODO: Read User from Keychain using key "fintrack.auth.user"
        // TODO: Return nil on Keychain read failure (treat as unauthenticated)
        return nil
    }

    func getSession() -> AuthSession? {
        // TODO: Read AuthSession from Keychain using key "fintrack.auth.session"
        // TODO: Return nil on Keychain read failure
        return nil
    }

    func signOut() throws {
        // TODO: Delete AuthSession from Keychain ("fintrack.auth.session")
        // TODO: Delete User from Keychain ("fintrack.auth.user")
    }
}
