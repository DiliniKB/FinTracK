import AuthenticationServices
// import GoogleSignIn   // Uncomment once SPM package is added

/// Abstracts third-party identity-provider sign-in flows (Apple, Google).
protocol IDPAuthService {
    /// Trigger the native Sign in with Apple sheet.
    /// - Returns: The raw `ASAuthorizationAppleIDCredential` on success.
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential

    /// Trigger the Google Sign-In flow.
    /// - Parameter presenting: The view controller to present the Google UI from.
    /// - Returns: The authenticated `GIDGoogleUser` on success.
    // TODO: Replace `Any` return type with `GIDGoogleUser` once GoogleSignIn SPM package is added
    func signInWithGoogle(presenting: Any) async throws -> Any
}

/// V1 concrete implementation of `IDPAuthService`.
class DefaultIDPAuthService: IDPAuthService {

    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential {
        // TODO: Create ASAuthorizationAppleIDProvider
        // TODO: Configure ASAuthorizationAppleIDRequest (requestedScopes: [.fullName, .email])
        // TODO: Use ASAuthorizationController with async/await continuation
        // TODO: Extract and return ASAuthorizationAppleIDCredential from result
        fatalError("Not implemented")
    }

    func signInWithGoogle(presenting: Any) async throws -> Any {
        // TODO: Cast `presenting` to UIViewController
        // TODO: Call GIDSignIn.sharedInstance.signIn(withPresenting:)
        // TODO: Return the resulting GIDGoogleUser
        fatalError("Not implemented")
    }
}
