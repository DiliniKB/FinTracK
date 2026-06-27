import SwiftUI

/// Root router view. Switches between auth screens and the main app
/// based on `AuthViewModel.state`.
struct AppRootView: View {

    @State private var authVM: AuthViewModel

    init(authVM: AuthViewModel) {
        self._authVM = State(initialValue: authVM)
    }

    var body: some View {
        // TODO: Switch on authVM.state and render the appropriate child view:
        //   .loading        → LoadingView()
        //   .unauthenticated → WelcomeScreen(vm: authVM)
        //   .locked          → LockScreen(vm: authVM)
        //   .authenticated   → HomeScreen()   (or the app's main tab view)
        //   .error(let msg)  → inline error / ErrorView(message: msg)
        EmptyView()
    }
}

#Preview {
    // TODO: Inject preview-friendly AuthViewModel with mock dependencies
    AppRootView(authVM: AuthViewModel(
        authRepository: PreviewAuthRepository(),
        biometricService: PreviewBiometricService(),
        idpAuthService: PreviewIDPAuthService()
    ))
}

// MARK: - Preview stubs (remove or move to a PreviewHelpers file before shipping)

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
