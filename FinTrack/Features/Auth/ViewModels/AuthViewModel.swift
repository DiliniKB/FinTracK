import Foundation
import Observation

/// Drives all authentication screens. Holds the canonical `AuthState` for the app.
@Observable
class AuthViewModel {

    // MARK: - State

    enum AuthState {
        case loading
        case unauthenticated        // No session → show WelcomeScreen
        case locked                 // Session exists → show LockScreen
        case authenticated(User)   // Ready → show HomeScreen
        case error(String)
    }

    var state: AuthState = .loading

    // MARK: - Dependencies

    private let authRepository: any AuthRepository
    private let biometricService: any BiometricService
    private let idpAuthService: any IDPAuthService

    init(
        authRepository: any AuthRepository,
        biometricService: any BiometricService,
        idpAuthService: any IDPAuthService
    ) {
        self.authRepository = authRepository
        self.biometricService = biometricService
        self.idpAuthService = idpAuthService
    }

    // MARK: - Actions

    /// Called on app launch. Checks Keychain for an existing session.
    func checkSession() {
        // TODO: Read session via authRepository.getSession()
        // TODO: If session exists → state = .locked
        // TODO: If no session → state = .unauthenticated
    }

    /// Prompts Face ID / Touch ID. On success transitions to .authenticated.
    func authenticateWithBiometric() {
        // TODO: Call biometricService.authenticate(reason:)
        // TODO: On success: fetch user via authRepository.getCurrentUser(), set state = .authenticated(user)
        // TODO: On failure: set state = .error(message) and surface retry + fallback option
    }

    /// Triggers Sign in with Apple flow via IDPAuthService → LocalAuthRepository.
    func signInWithApple() {
        // TODO: Call idpAuthService.signInWithApple()
        // TODO: Pass credential to authRepository.signInWithApple(credential:)
        // TODO: On success: set state = .authenticated(user)
        // TODO: On failure: set state = .error(message)
    }

    /// Triggers Sign in with Google flow via IDPAuthService → LocalAuthRepository.
    func signInWithGoogle() {
        // TODO: Obtain presenting UIViewController
        // TODO: Call idpAuthService.signInWithGoogle(presenting:)
        // TODO: Pass credential to authRepository.signInWithGoogle(credential:)
        // TODO: On success: set state = .authenticated(user)
        // TODO: On cancelled: silently return to WelcomeScreen (no error shown)
        // TODO: On failure: set state = .error(message)
    }

    /// Clears the local session and returns to WelcomeScreen.
    func signOut() {
        // TODO: Call authRepository.signOut()
        // TODO: Set state = .unauthenticated
        // TODO: Handle and log any Keychain errors
    }
}
