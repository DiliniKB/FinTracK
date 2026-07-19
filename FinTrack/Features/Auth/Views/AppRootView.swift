import AuthenticationServices
import GoogleSignIn
import SwiftData
import SwiftUI

/// Root router. Switches the view hierarchy based on `AuthViewModel.state`.
/// Tracks the last stable (non-error) screen so errors from biometric context
/// still show LockScreen, and errors from sign-in context still show WelcomeScreen.
struct AppRootView: View {

    @State private var authVM: AuthViewModel
    /// Remembers whether the last non-error screen was the lock screen.
    /// Used to route `.error` state to the correct underlying screen.
    @State private var lockedContext = false

    @Environment(\.modelContext) private var modelContext

    // SMS coordinator is created on first appear once modelContext is available.
    @State private var smsCoordinator: SMSCoordinator?

    init(authVM: AuthViewModel) {
        self._authVM = State(initialValue: authVM)
    }

    // Stable string id that changes whenever the base state changes —
    // used by .task(id:) to detect transitions without requiring Equatable.
    private var stateRouteID: String {
        switch authVM.state {
        case .loading:                  return "loading"
        case .unauthenticated:          return "unauthenticated"
        case .locked:                   return "locked"
        case .authenticated(let user):  return "authenticated-\(user.id)"
        case .error(let msg):           return "error-\(msg)"
        }
    }

    var body: some View {
        Group {
            switch authVM.state {
            case .loading:
                loadingView

            case .unauthenticated:
                WelcomeScreen(vm: authVM)

            case .locked:
                LockScreen(vm: authVM)

            case .authenticated:
                mainTabView

            case .error:
                // Show the screen that owns the error so it can render inline.
                if lockedContext {
                    LockScreen(vm: authVM)
                } else {
                    WelcomeScreen(vm: authVM)
                }
            }
        }
        // Track the last stable screen so .error routes correctly.
        .task(id: stateRouteID) {
            switch authVM.state {
            case .locked:          lockedContext = true
            case .unauthenticated: lockedContext = false
            default:               break
            }
        }
        .onAppear {
            guard smsCoordinator == nil else { return }
            let catRepo = SwiftDataCategoryRepository(context: modelContext)
            smsCoordinator = SMSCoordinator(
                parser:              NLSMSParserService(),
                notificationService: SMSNotificationService(),
                categoryRepository:  catRepo
            )
            Task { await smsCoordinator?.requestNotificationPermission() }
        }
        .onOpenURL { url in
            guard url.scheme == "fintrack",
                  url.host == "sms",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let smsText = components.queryItems?.first(where: { $0.name == "text" })?.value
            else { return }
            let sender = components.queryItems?.first(where: { $0.name == "sender" })?.value
            smsCoordinator?.handle(smsText: smsText, sender: sender)
        }
        .sheet(isPresented: Binding(
            get: { smsCoordinator?.showConfirmation ?? false },
            set: { if !$0 { smsCoordinator?.dismiss() } }
        )) {
            if let coordinator = smsCoordinator,
               let result = coordinator.pendingResult {
                SMSConfirmationSheet(
                    result:                result,
                    coordinator:           coordinator,
                    categoryRepository:    SwiftDataCategoryRepository(context: modelContext),
                    transactionRepository: SwiftDataTransactionRepository(context: modelContext)
                )
            }
        }
    }

    // MARK: - Private sub-views

    private var loadingView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
        }
    }

    private var mainTabView: some View {
        TabView {
            TransactionsScreen()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            BudgetScreen()
                .tabItem {
                    Label("Budgets", systemImage: "chart.bar.fill")
                }
            CategoriesScreen()
                .tabItem {
                    Label("Categories", systemImage: "tag.fill")
                }
        }
    }
}

// MARK: - Preview

#Preview("Unauthenticated") {
    AppRootView(authVM: AuthViewModel(
        authRepository:   PreviewAuthRepository(session: nil),
        biometricService: PreviewBiometricService(),
        idpAuthService:   PreviewIDPAuthService()
    ))
}

#Preview("Locked") {
    AppRootView(authVM: AuthViewModel(
        authRepository:   PreviewAuthRepository(session: .preview),
        biometricService: PreviewBiometricService(),
        idpAuthService:   PreviewIDPAuthService()
    ))
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
    var isAvailable: Bool  { false }
    var biometricType: BiometricType { .faceID }
    func authenticate(reason: String) async throws -> Bool { false }
}

private struct PreviewIDPAuthService: IDPAuthService {
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential { fatalError() }
    func signInWithGoogle() async throws -> GIDGoogleUser { fatalError() }
}

private extension AuthSession {
    static let preview = AuthSession(userId: "preview", provider: .apple, createdAt: .now)
}
