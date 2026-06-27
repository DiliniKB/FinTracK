import AuthenticationServices
// GoogleSignIn import will be needed once the SPM package is added:
// import GoogleSignIn

/// Defines the contract for all authentication operations.
/// V1: implemented by `LocalAuthRepository` (Keychain only).
/// V2: swap for `RemoteAuthRepository` — no ViewModel/UI changes required.
protocol AuthRepository {
    // TODO: Replace `Any` with `ASAuthorizationAppleIDCredential` once AuthenticationServices is linked
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    // TODO: Replace `Any` with `GIDGoogleUser` once GoogleSignIn SPM package is added
    func signInWithGoogle(credential: Any) async throws -> User
    func getCurrentUser() -> User?
    func getSession() -> AuthSession?
    func signOut() throws
}
