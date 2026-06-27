import SwiftUI

/// Shown when a session exists but the app is locked.
/// Auto-triggers biometric authentication on appear.
///
/// States: prompting | failed (retry button) | fallback triggered
struct LockScreen: View {

    var vm: AuthViewModel

    var body: some View {
        // TODO: App logo (centered, minimal layout)
        // TODO: Biometric icon (Face ID or Touch ID depending on BiometricService.biometricType)
        // TODO: On .onAppear → call vm.authenticateWithBiometric()
        // TODO: On failure → show "Try Again" button → calls vm.authenticateWithBiometric()
        // TODO: "Use password" / "Sign in again" fallback → calls vm.signOut()
        //        which clears the session and transitions to WelcomeScreen
        EmptyView()
    }
}

#Preview {
    // TODO: Inject preview AuthViewModel in .locked state
    LockScreen(vm: AuthViewModel(
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
