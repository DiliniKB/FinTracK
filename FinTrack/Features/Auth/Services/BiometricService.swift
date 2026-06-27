import Foundation
import LocalAuthentication

// MARK: - Error

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case userCancelled
    case userFallback        // User tapped "Enter Password" — treat as fallback trigger
    case authenticationFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No biometrics are enrolled. Please set up Face ID or Touch ID in Settings."
        case .userCancelled:
            return "Authentication was cancelled."
        case .userFallback:
            return "Biometric authentication skipped — please sign in again."
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Enum

/// The type of biometric hardware available on the device.
enum BiometricType {
    case faceID
    case touchID
    case none
}

// MARK: - Protocol

/// Abstracts biometric authentication (Face ID / Touch ID) via LocalAuthentication.
protocol BiometricService {
    /// Whether the device supports biometrics and has them enrolled.
    var isAvailable: Bool { get }
    /// The specific biometric modality available on this device.
    var biometricType: BiometricType { get }
    /// Prompt the user for biometric authentication.
    /// - Returns: `true` on success.
    /// - Throws: `BiometricError` describing what went wrong.
    func authenticate(reason: String) async throws -> Bool
}

// MARK: - Default Implementation

/// Concrete implementation using `LAContext`.
/// A fresh `LAContext` is created per `authenticate` call so that a failed
/// attempt doesn't poison subsequent prompts.
final class DefaultBiometricService: BiometricService {

    // MARK: - Availability

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var biometricType: BiometricType {
        let context = LAContext()
        // canEvaluatePolicy must be called first to populate context.biometryType.
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:   return .faceID
        case .touchID:  return .touchID
        default:        return .none
        }
    }

    // MARK: - Authentication

    func authenticate(reason: String) async throws -> Bool {
        // Use a fresh context each call — a context whose evaluation failed
        // cannot be reused for a new biometric prompt.
        let context = LAContext()

        // Verify availability (and surface a typed error) before prompting.
        var policyError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                        error: &policyError) else {
            throw mapPolicyError(policyError)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapLAError(error)
        }
    }

    // MARK: - Error Mapping

    private func mapPolicyError(_ error: NSError?) -> BiometricError {
        guard let error else { return .notAvailable }
        switch LAError.Code(rawValue: error.code) {
        case .biometryNotAvailable:  return .notAvailable
        case .biometryNotEnrolled:   return .notEnrolled
        default:                     return .unknown(error)
        }
    }

    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else { return .unknown(error) }
        switch laError.code {
        case .biometryNotAvailable:    return .notAvailable
        case .biometryNotEnrolled:     return .notEnrolled
        case .userCancel:              return .userCancelled
        case .userFallback:            return .userFallback
        case .authenticationFailed:    return .authenticationFailed
        default:                       return .unknown(laError)
        }
    }
}
