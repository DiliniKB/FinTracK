import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Preferences (persisted via UserDefaults)

    var budgetAlertsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "budgetAlertsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "budgetAlertsEnabled")
            if newValue { Task { await requestNotificationPermission() } }
        }
    }

    var biometricLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricLockEnabled") }
    }

    // MARK: - Sheet / alert control

    var showSignOutAlert = false

    // MARK: - Dependencies

    private let authViewModel: AuthViewModel
    private let biometricService: any BiometricService

    init(authViewModel: AuthViewModel, biometricService: any BiometricService) {
        self.authViewModel    = authViewModel
        self.biometricService = biometricService
    }

    // MARK: - Derived

    var currentUser: User? {
        if case .authenticated(let user) = authViewModel.state { return user }
        return nil
    }

    var biometricLabel: String {
        biometricService.biometricType == .faceID ? "Face ID" : "Touch ID"
    }

    var biometricAvailable: Bool { biometricService.isAvailable }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    // MARK: - Actions

    func signOut() {
        authViewModel.signOut()
    }

    // MARK: - Private

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if !granted {
            // Permission denied — revert the toggle
            UserDefaults.standard.set(false, forKey: "budgetAlertsEnabled")
        }
    }
}
