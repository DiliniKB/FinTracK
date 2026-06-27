import Foundation
import LocalAuthentication

/// The type of biometric hardware available on the device.
enum BiometricType {
    case faceID
    case touchID
    case none
}

/// Abstracts biometric authentication (Face ID / Touch ID) via LocalAuthentication.
protocol BiometricService {
    /// Whether the device supports and has biometrics enrolled.
    var isAvailable: Bool { get }
    /// The specific biometric modality available on this device.
    var biometricType: BiometricType { get }
    /// Prompt the user for biometric authentication.
    /// - Returns: `true` on success.
    /// - Throws: `LAError` on failure or cancellation.
    func authenticate(reason: String) async throws -> Bool
}

/// V1 concrete implementation using `LAContext`.
class DefaultBiometricService: BiometricService {

    private let context = LAContext()

    var isAvailable: Bool {
        // TODO: Call context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:)
        return false
    }

    var biometricType: BiometricType {
        // TODO: Check context.biometryType after calling canEvaluatePolicy
        // TODO: Map LABiometryType (.faceID / .touchID / .none) to BiometricType
        return .none
    }

    func authenticate(reason: String) async throws -> Bool {
        // TODO: Call context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        // TODO: Return result; propagate LAError on failure
        return false
    }
}
