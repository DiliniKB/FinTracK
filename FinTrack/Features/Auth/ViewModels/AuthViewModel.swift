import AuthenticationServices
import Foundation
import Observation

/// Drives all authentication screens. Holds the canonical `AuthState` for the app.
/// All state mutations are performed on the `@MainActor` so SwiftUI updates
/// are always delivered on the main thread.
@Observable
@MainActor
final class AuthViewModel {

    // MARK: - State

    enum AuthState {
        case loading
        case unauthenticated        // No session → show WelcomeScreen
        case locked                 // Session exists, biometric needed → show LockScreen
        case authenticated(User)    // Ready → show HomeScreen
        case error(String)          // Inline error — retain previous logical state via errorContext
    }

    private(set) var state: AuthState = .loading

    // MARK: - Dependencies

    private let authRepository:  any AuthRepository
    private let biometricService: any BiometricService
    private let idpAuthService:   any IDPAuthService

    init(
        authRepository:  any AuthRepository,
        biometricService: any BiometricService,
        idpAuthService:   any IDPAuthService
    ) {
        self.authRepository   = authRepository
        self.biometricService = biometricService
        self.idpAuthService   = idpAuthService
        checkSession()
    }

    // MARK: - checkSession

    /// Reads the Keychain for an existing session on app launch.
    /// Transitions to `.locked` if one exists, `.unauthenticated` otherwise.
    func checkSession() {
        if authRepository.getSession() != nil {
            state = .locked
        } else {
            state = .unauthenticated
        }
    }

    // MARK: - authenticateWithBiometric

    /// Prompts Face ID / Touch ID.
    /// - Success → `.authenticated`
    /// - `userFallback` → sign out + `.unauthenticated` (spec AUTH-04)
    /// - All other failures → `.error` with retry message
    func authenticateWithBiometric() {
        Task {
            do {
                _ = try await biometricService.authenticate(
                    reason: "Unlock FinTrack to access your finances."
                )
                // Biometric passed — load the persisted user.
                guard let user = authRepository.getCurrentUser() else {
                    // Session existed but user record is gone — treat as signed out.
                    signOut()
                    return
                }
                state = .authenticated(user)
            } catch BiometricError.userFallback {
                // User tapped the fallback button. Clear the session so
                // WelcomeScreen is shown and they can re-authenticate via IDP.
                signOut()
            } catch BiometricError.userCancelled {
                // User dismissed the prompt — stay on LockScreen, no error banner.
                state = .locked
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - signInWithApple

    /// Triggers Sign in with Apple: IDPAuthService → LocalAuthRepository → `.authenticated`.
    func signInWithApple() {
        Task {
            do {
                let credential = try await idpAuthService.signInWithApple()
                let user       = try await authRepository.signInWithApple(credential: credential)
                state = .authenticated(user)
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // User cancelled the sheet — return silently, no error banner.
                return
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - signInWithGoogle

    /// Triggers Sign in with Google: IDPAuthService → LocalAuthRepository → `.authenticated`.
    func signInWithGoogle() {
        Task {
            do {
                let googleUser = try await idpAuthService.signInWithGoogle()
                let user       = try await authRepository.signInWithGoogle(credential: googleUser)
                state = .authenticated(user)
            } catch IDPAuthError.googleCancelled {
                // User cancelled — return silently, no error banner (spec §11).
                return
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - signOut

    /// Clears the local Keychain session and returns to WelcomeScreen.
    /// Errors from Keychain deletion are logged but do not block the transition —
    /// the user must always be able to reach the sign-in screen.
    func signOut() {
        do {
            try authRepository.signOut()
        } catch {
            // Non-fatal: log and proceed. The session may already be missing
            // (reinstall edge case, spec §11).
            print("[AuthViewModel] signOut Keychain error (non-fatal): \(error)")
        }
        state = .unauthenticated
    }
}
