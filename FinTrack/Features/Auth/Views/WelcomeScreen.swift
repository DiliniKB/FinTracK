import AuthenticationServices
import GoogleSignIn
import SwiftUI

/// First screen shown to unauthenticated users.
/// States: default | loading (buttons disabled + spinner) | error (inline red message)
struct WelcomeScreen: View {

    var vm: AuthViewModel

    /// Tracks which IDP button is in-flight so only that button shows a spinner.
    @State private var signingInWithApple  = false
    @State private var signingInWithGoogle = false

    // MARK: - Derived state

    private var isLoading: Bool {
        signingInWithApple || signingInWithGoogle
    }

    private var errorMessage: String? {
        if case .error(let msg) = vm.state { return msg }
        return nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + app name
                logoSection

                Spacer()

                // Buttons + error
                VStack(spacing: 12) {
                    appleSignInButton
                    googleSignInButton

                    if let message = errorMessage {
                        errorBanner(message)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        // Clear in-flight flags when state settles (success, error, or cancellation).
        .onChange(of: isLoading) { _, loading in
            if !loading {
                signingInWithApple  = false
                signingInWithGoogle = false
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.blue)

            Text("FinTrack")
                .font(.system(size: 40, weight: .bold, design: .rounded))

            Text("Your finances, simplified.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sign in with Apple

    /// Custom-styled button that mirrors the native Apple sign-in button appearance
    /// while routing through `AuthViewModel` → `IDPAuthService` → `LocalAuthRepository`.
    private var appleSignInButton: some View {
        Button {
            guard !isLoading else { return }
            signingInWithApple = true
            vm.signInWithApple()
        } label: {
            HStack(spacing: 8) {
                if signingInWithApple {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.body.bold())
                }
                Text("Sign in with Apple")
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(isLoading)
    }

    // MARK: - Sign in with Google

    private var googleSignInButton: some View {
        Button {
            guard !isLoading else { return }
            signingInWithGoogle = true
            vm.signInWithGoogle()
        } label: {
            HStack(spacing: 10) {
                if signingInWithGoogle {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                } else {
                    // Stylised "G" — replaced by the real Google logo asset once available.
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 26, height: 26)
                        Text("G")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(red: 0.259, green: 0.522, blue: 0.957))
                    }
                }
                Text("Sign in with Google")
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(Color(red: 0.259, green: 0.522, blue: 0.957))  // #4285F4
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(isLoading)
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
}

// MARK: - Preview

#Preview("Default") {
    WelcomeScreen(vm: AuthViewModel(
        authRepository:   PreviewAuthRepository(state: .unauthenticated),
        biometricService: PreviewBiometricService(),
        idpAuthService:   PreviewIDPAuthService()
    ))
}

#Preview("Error") {
    WelcomeScreen(vm: AuthViewModel(
        authRepository:   PreviewAuthRepository(state: .error("Google Sign-In failed. Please try again.")),
        biometricService: PreviewBiometricService(),
        idpAuthService:   PreviewIDPAuthService()
    ))
}

// MARK: - Preview stubs

private struct PreviewAuthRepository: AuthRepository {
    let forcedState: AuthViewModel.AuthState?
    init(state: AuthViewModel.AuthState? = nil) { self.forcedState = state }
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User { fatalError() }
    func signInWithGoogle(credential: GIDGoogleUser) async throws -> User { fatalError() }
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
    func signInWithGoogle() async throws -> GIDGoogleUser { fatalError() }
}
