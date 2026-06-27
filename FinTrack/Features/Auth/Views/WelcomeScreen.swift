import SwiftUI
import AuthenticationServices

/// First screen shown to unauthenticated users.
/// Contains Sign in with Apple and Sign in with Google buttons.
///
/// States: default | loading (spinner) | error (inline message)
struct WelcomeScreen: View {

    var vm: AuthViewModel

    var body: some View {
        // TODO: App logo + tagline (centered)
        // TODO: ASAuthorizationAppleIDButton (native) → calls vm.signInWithApple()
        // TODO: "Sign in with Google" custom button → calls vm.signInWithGoogle()
        // TODO: Show loading spinner on button while state == .loading
        // TODO: Show inline error message below buttons when state == .error(msg)
        EmptyView()
    }
}

#Preview {
    // TODO: Inject preview AuthViewModel
    WelcomeScreen(vm: AuthViewModel(
        authRepository: PreviewAuthRepository(),
        biometricService: PreviewBiometricService(),
        idpAuthService: PreviewIDPAuthService()
    ))
}

// MARK: - Preview stubs

private struct PreviewAuthRepository: AuthRepository {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User { fatalError() }
    func signInWithGoogle(credential: Any) async throws -> User { fatalError() }
    func getCurrentUser() -> User? { nil }
    func getSession() -> AuthSession? { nil }
    func signOut() throws {}
}

private struct PreviewBiometricService: BiometricService {
    var isAvailable: Bool { false }
    var biometricType: BiometricType { .none }
    func authenticate(reason: String) async throws -> Bool { false }
}

private struct PreviewIDPAuthService: IDPAuthService {
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential { fatalError() }
    func signInWithGoogle(presenting: Any) async throws -> Any { fatalError() }
}
