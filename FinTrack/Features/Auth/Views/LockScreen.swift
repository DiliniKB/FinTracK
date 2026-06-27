import AuthenticationServices
import GoogleSignIn
import SwiftUI

/// Shown when a session exists but the app is locked.
/// Auto-triggers biometric authentication on appear.
/// States: prompting | failed/error (retry button) | fallback triggered → WelcomeScreen
struct LockScreen: View {

    var vm: AuthViewModel
    private let biometricService: any BiometricService

    init(vm: AuthViewModel, biometricService: any BiometricService = DefaultBiometricService()) {
        self.vm = vm
        self.biometricService = biometricService
    }

    // MARK: - Derived state

    private var errorMessage: String? {
        if case .error(let msg) = vm.state { return msg }
        return nil
    }

    private var biometricSymbol: String {
        switch biometricService.biometricType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .none:    return "lock.fill"
        }
    }

    private var biometricLabel: String {
        switch biometricService.biometricType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .none:    return "Biometrics"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App logo + biometric icon
                VStack(spacing: 24) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.blue)

                    Text("FinTrack")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    biometricPromptIcon
                }

                Spacer()

                // Error + retry / prompting indicator
                VStack(spacing: 16) {
                    if let message = errorMessage {
                        errorBanner(message)
                        retryButton
                    } else {
                        promptingIndicator
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Fallback — always visible at bottom
                signInAgainButton
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            vm.authenticateWithBiometric()
        }
    }

    // MARK: - Biometric prompt icon

    private var biometricPromptIcon: some View {
        VStack(spacing: 8) {
            Image(systemName: biometricSymbol)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, isActive: errorMessage == nil)

            Text("Unlock with \(biometricLabel)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Prompting indicator

    private var promptingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Waiting for \(biometricLabel)…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Retry

    private var retryButton: some View {
        Button {
            vm.authenticateWithBiometric()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                Text("Try Again")
            }
            .font(.body.bold())
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Sign in again (fallback)

    private var signInAgainButton: some View {
        Button(role: .destructive) {
            // Clears the Keychain session and transitions to WelcomeScreen
            // so the user can re-authenticate via Apple or Google (spec AUTH-04).
            vm.signOut()
        } label: {
            Text("Sign in again")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .underline()
        }
    }
}

// MARK: - Preview

#Preview("Prompting") {
    LockScreen(
        vm: AuthViewModel(
            authRepository:   PreviewAuthRepository(session: .preview),
            biometricService: PreviewBiometricService(type: .faceID),
            idpAuthService:   PreviewIDPAuthService()
        ),
        biometricService: PreviewBiometricService(type: .faceID)
    )
}

#Preview("Failed") {
    let vm = AuthViewModel(
        authRepository:   PreviewAuthRepository(session: .preview),
        biometricService: PreviewBiometricService(type: .touchID, failWith: BiometricError.authenticationFailed),
        idpAuthService:   PreviewIDPAuthService()
    )
    return LockScreen(vm: vm, biometricService: PreviewBiometricService(type: .touchID))
}

#Preview("No Biometrics") {
    LockScreen(
        vm: AuthViewModel(
            authRepository:   PreviewAuthRepository(session: .preview),
            biometricService: PreviewBiometricService(type: .none),
            idpAuthService:   PreviewIDPAuthService()
        ),
        biometricService: PreviewBiometricService(type: .none)
    )
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
    var type: BiometricType
    var error: Error?

    init(type: BiometricType, failWith error: Error? = nil) {
        self.type  = type
        self.error = error
    }

    var isAvailable: Bool { type != .none }
    var biometricType: BiometricType { type }

    func authenticate(reason: String) async throws -> Bool {
        if let error { throw error }
        return true
    }
}

private struct PreviewIDPAuthService: IDPAuthService {
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential { fatalError() }
    func signInWithGoogle() async throws -> GIDGoogleUser { fatalError() }
}

private extension AuthSession {
    static let preview = AuthSession(userId: "preview", provider: .apple, createdAt: .now)
}
