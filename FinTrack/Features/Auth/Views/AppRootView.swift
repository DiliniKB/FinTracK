import AuthenticationServices
import GoogleSignIn
import SwiftUI

/// Root router. Switches the view hierarchy based on `AuthViewModel.state`.
/// Tracks the last stable (non-error) screen so errors from biometric context
/// still show LockScreen, and errors from sign-in context still show WelcomeScreen.
struct AppRootView: View {

    @State private var authVM: AuthViewModel
    /// Remembers whether the last non-error screen was the lock screen.
    /// Used to route `.error` state to the correct underlying screen.
    @State private var lockedContext = false

    init(authVM: AuthViewModel) {
        self._authVM = State(initialValue: authVM)
    }

    // Stable string id that changes whenever the base state changes —
    // used by .task(id:) to detect transitions without requiring Equatable.
    private var stateRouteID: String {
        switch authVM.state {
        case .loading:                  return "loading"
        case .unauthenticated:          return "unauthenticated"
        case .locked:                   return "locked"
        case .authenticated(let user):  return "authenticated-\(user.id)"
        case .error(let msg):           return "error-\(msg)"
        }
    }

    var body: some View {
        Group {
            switch authVM.state {
            case .loading:
                loadingView

            case .unauthenticated:
                WelcomeScreen(vm: authVM)

            case .locked:
                LockScreen(vm: authVM)

            case .authenticated:
                // TODO: Replace with the app's main TabView / HomeScreen
                placeholderHomeView

            case .error:
                // Show the screen that owns the error so it can render inline.
                if lockedContext {
                    LockScreen(vm: authVM)
                } else {
                    WelcomeScreen(vm: authVM)
                }
            }
        }
        // Track the last stable screen so .error routes correctly.
        .task(id: stateRouteID) {
            switch authVM.state {
            case .locked:          lockedContext = true
            case .unauthenticated: lockedContext = false
            default:               break
            }
        }
    }

    // MARK: - Private sub-views

    private var loadingView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
        }
    }

    private var placeholderHomeView: some View {
        // TODO: Replace with HomeScreen() once the main app is implemented.
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                Text("Welcome to FinTrack")
                    .font(.title2.bold())
                Button("Sign Out", role: .destructive) {
                    authVM.signOut()
                }
                .padding(.top, 8)
            }
            .navigationTitle("Home")
        }
    }
}

// MARK: - Preview

#Preview("Unauthenticated") {
    AppRootView(authVM: AuthViewModel(
        authRepository:   PreviewAuthRepository(session: nil),
        biometricService: PreviewBiometricService(),
        idpAuthService:   PreviewIDPAuthService()
    ))
}

#Preview("Locked") {
    AppRootView(authVM: AuthViewModel(
        authRepository:   PreviewAuthRepository(session: .preview),
        biometricService: PreviewBiometricService(),
        idpAuthService:   PreviewIDPAuthService()
    ))
}

// MARK: - Preview stubs

private struct PreviewAuthRepository: AuthRepository {
    let session: AuthSession?
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User { fatalError() }
    func signInWithGoogle(credential: GIDGoogleUser) async throws -> User { fatalError() }
    func getCurrentUser() -> User? { nil }
    func getSession() -> AuthSession? { session }
    func signOut() throws {}
}

private struct PreviewBiometricService: BiometricService {
    var isAvailable: Bool  { false }
    var biometricType: BiometricType { .faceID }
    func authenticate(reason: String) async throws -> Bool { false }
}

private struct PreviewIDPAuthService: IDPAuthService {
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential { fatalError() }
    func signInWithGoogle() async throws -> GIDGoogleUser { fatalError() }
}

private extension AuthSession {
    static let preview = AuthSession(userId: "preview", provider: .apple, createdAt: .now)
}
