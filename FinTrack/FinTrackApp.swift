//
//  FinTrackApp.swift
//  FinTrack
//
//  Created by Dilini Bandara on 2026-06-27.
//

import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct FinTrackApp: App {

    // MARK: - Init

    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
    }

    // MARK: - Auth dependency graph

    private let authViewModel: AuthViewModel = {
        let keychain   = DefaultKeychainService()
        let biometric  = DefaultBiometricService()
        let idp        = DefaultIDPAuthService()
        let repository = LocalAuthRepository(keychainService: keychain)
        return AuthViewModel(
            authRepository:   repository,
            biometricService: biometric,
            idpAuthService:   idp
        )
    }()

    // MARK: - SwiftData

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(AppSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            AppRootView(authVM: authViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
