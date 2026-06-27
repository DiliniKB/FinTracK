import AuthenticationServices
import UIKit
import GoogleSignIn

// MARK: - Error

enum IDPAuthError: LocalizedError {
    case appleCredentialInvalid
    case noRootViewController
    case googleCancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .appleCredentialInvalid:
            return "Sign in with Apple returned an unexpected credential type."
        case .noRootViewController:
            return "Unable to find a view controller to present the sign-in sheet."
        case .googleCancelled:
            return "Google sign-in was cancelled."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Protocol

/// Abstracts third-party identity-provider sign-in flows (Apple, Google).
protocol IDPAuthService {
    /// Trigger the native Sign in with Apple sheet.
    /// - Returns: The raw credential on success.
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential

    /// Trigger the Google Sign-In flow, auto-sourcing the presenting view controller.
    /// - Returns: The authenticated Google user on success.
    func signInWithGoogle() async throws -> GIDGoogleUser
}

// MARK: - Default Implementation

/// Concrete implementation of `IDPAuthService`.
final class DefaultIDPAuthService: NSObject, IDPAuthService {

    // Held strongly for the duration of the Apple sign-in presentation.
    // @MainActor ensures reads and writes are confined to the main thread,
    // preventing data races between the caller and delegate callbacks.
    @MainActor private var appleSignInContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    // MARK: - Sign in with Apple

    @MainActor
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request  = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate                    = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async throws -> GIDGoogleUser {
        guard let viewController = rootViewController() else {
            throw IDPAuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        return result.user
    }

    // MARK: - Helpers

    /// Walks the active UIWindowScene to find the key window's root view controller,
    /// following any presented chain to the topmost controller.
    private func rootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        var root = scene?.keyWindow?.rootViewController
        while let presented = root?.presentedViewController {
            root = presented
        }
        return root
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension DefaultIDPAuthService: ASAuthorizationControllerDelegate {

    @MainActor
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            appleSignInContinuation?.resume(throwing: IDPAuthError.appleCredentialInvalid)
            appleSignInContinuation = nil
            return
        }
        appleSignInContinuation?.resume(returning: credential)
        appleSignInContinuation = nil
    }

    @MainActor
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError = error as? ASAuthorizationError
        // ASAuthorizationError.canceled is user-initiated — surface it distinctly
        // so AuthViewModel can return silently without showing an error banner.
        if authError?.code == .canceled {
            appleSignInContinuation?.resume(throwing: ASAuthorizationError(.canceled))
        } else {
            appleSignInContinuation?.resume(throwing: IDPAuthError.unknown(error))
        }
        appleSignInContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension DefaultIDPAuthService: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Walk connected scenes for the active foreground window to anchor the sheet.
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.keyWindow ?? UIWindow(windowScene:
            UIApplication.shared.connectedScenes.first as! UIWindowScene)
    }
}
