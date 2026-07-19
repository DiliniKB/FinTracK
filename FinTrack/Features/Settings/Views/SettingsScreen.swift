import SwiftUI

struct SettingsScreen: View {

    @State private var vm: SettingsViewModel

    init(authVM: AuthViewModel, biometricService: any BiometricService) {
        _vm = State(initialValue: SettingsViewModel(
            authViewModel:    authVM,
            biometricService: biometricService
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                manageSection
                preferencesSection
                accountSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $vm.showSignOutAlert) {
                Button("Sign Out", role: .destructive) { vm.signOut() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will be returned to the sign-in screen.")
            }
        }
    }

    // MARK: - Manage

    private var manageSection: some View {
        Section("Manage") {
            NavigationLink {
                CategoriesScreen()
            } label: {
                Label("Categories", systemImage: "tag.fill")
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: $vm.budgetAlertsEnabled) {
                Label("Budget Alerts", systemImage: "bell.fill")
            }

            if vm.biometricAvailable {
                Toggle(isOn: $vm.biometricLockEnabled) {
                    Label(vm.biometricLabel, systemImage: "faceid")
                }
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            if let user = vm.currentUser {
                HStack {
                    Label(user.email, systemImage: "person.circle")
                        .lineLimit(1)
                    Spacer()
                    providerBadge(user.provider)
                }
            }

            Button(role: .destructive) {
                vm.showSignOutAlert = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("FinTrack")
                Spacer()
                Text("v\(vm.appVersion)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func providerBadge(_ provider: AuthProvider) -> some View {
        Text(provider == .apple ? "Apple" : "Google")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(.systemFill))
            .clipShape(Capsule())
    }
}
