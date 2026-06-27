import AuthenticationServices
import GoogleSignIn

/// Defines the contract for all authentication operations.
/// V1: implemented by `LocalAuthRepository` (Keychain only).
/// V2: swap for `RemoteAuthRepository` — no ViewModel/UI changes required.
protocol AuthRepository {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    func signInWithGoogle(credential: GIDGoogleUser) async throws -> User
    func getCurrentUser() -> User?
    func getSession() -> AuthSession?
    func signOut() throws
}
