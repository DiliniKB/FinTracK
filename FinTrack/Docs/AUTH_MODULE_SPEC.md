# Auth Module Spec — V1 (Local Only)
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
Gate app access using social identity (Apple/Google) and protect it with biometric lock. No backend in V1 — all data is local.

### Scope
- Sign in with Apple
- Sign in with Google
- Face ID / Touch ID lock
- Local session persistence (Keychain)
- Sign out

### Out of Scope (V2)
- JWT token management
- Token refresh
- Backend authentication
- Remote session sync

---

## 2. User Stories

| ID | Story |
|---|---|
| AUTH-01 | As a new user, I can sign in with Apple to create a local profile |
| AUTH-02 | As a new user, I can sign in with Google to create a local profile |
| AUTH-03 | As a returning user, I am prompted with Face ID / Touch ID on app launch |
| AUTH-04 | As a user, if biometric fails, I can re-authenticate via social login |
| AUTH-05 | As a user, I can sign out and clear my local session |

---

## 3. Data Models

### User
```swift
struct User: Codable {
    let id: String           // IDP-provided unique ID
    let name: String
    let email: String
    let provider: AuthProvider
    let createdAt: Date
}

enum AuthProvider: String, Codable {
    case apple
    case google
}
```

### AuthSession
```swift
struct AuthSession: Codable {
    let userId: String
    let provider: AuthProvider
    let createdAt: Date
    // V2: add accessToken, refreshToken here
}
```

---

## 4. Keychain Storage

| Key | Type | Description |
|---|---|---|
| `fintrack.auth.session` | `AuthSession` (JSON) | Active session |
| `fintrack.auth.user` | `User` (JSON) | User profile |

> Never store in UserDefaults. Keychain only.

---

## 5. Repository Layer

### Protocol (V1 + V2 compatible)
```swift
protocol AuthRepository {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    func signInWithGoogle(credential: GIDGoogleUser) async throws -> User
    func getCurrentUser() -> User?
    func getSession() -> AuthSession?
    func signOut() throws
}
```

### V1 Implementation
```swift
class LocalAuthRepository: AuthRepository {
    private let keychainService: KeychainService

    func signInWithApple(credential: ...) async throws -> User {
        // Extract name, email, userIdentifier from credential
        // Create User + AuthSession
        // Store both in Keychain
        // Return User
    }

    func signInWithGoogle(credential: ...) async throws -> User {
        // Extract profile from GIDGoogleUser
        // Create User + AuthSession
        // Store in Keychain
        // Return User
    }

    func getCurrentUser() -> User? {
        // Read from Keychain
    }

    func signOut() throws {
        // Delete session + user from Keychain
    }
}
```

---

## 6. Services

### KeychainService
```swift
protocol KeychainService {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func read<T: Codable>(forKey key: String) throws -> T?
    func delete(forKey key: String) throws
}
```

### BiometricService
```swift
protocol BiometricService {
    var isAvailable: Bool { get }
    var biometricType: BiometricType { get }   // .faceID / .touchID / .none
    func authenticate(reason: String) async throws -> Bool
}

enum BiometricType {
    case faceID, touchID, none
}
```

### IDPAuthService
```swift
protocol IDPAuthService {
    func signInWithApple() async throws -> ASAuthorizationAppleIDCredential
    func signInWithGoogle(presenting: UIViewController) async throws -> GIDGoogleUser
}
```

---

## 7. ViewModel

```swift
@Observable
class AuthViewModel {

    enum AuthState {
        case loading
        case unauthenticated        // No session → show WelcomeScreen
        case locked                 // Session exists → show LockScreen
        case authenticated(User)    // Ready → show Home
        case error(String)
    }

    var state: AuthState = .loading

    // Actions
    func checkSession()             // On app launch
    func authenticateWithBiometric()
    func signInWithApple()
    func signInWithGoogle()
    func signOut()
}
```

---

## 8. App Launch Flow

```
App Launch
    ↓
AuthViewModel.checkSession()
    ↓
Session in Keychain?
    ├── No  → state = .unauthenticated → WelcomeScreen
    └── Yes → state = .locked → LockScreen
                    ↓
              BiometricService.authenticate()
                    ├── Success → state = .authenticated → HomeScreen
                    └── Failure → show retry + "Sign in again" fallback
                                    ↓
                              Sign in again → clears session → WelcomeScreen
```

---

## 9. UI Screens

### WelcomeScreen
- App logo + tagline
- "Sign in with Apple" button (ASAuthorizationAppleIDButton — native)
- "Sign in with Google" button
- No email/password fields

**States:**
- Default
- Loading (spinner on button)
- Error (inline message below button)

---

### LockScreen
- Minimal — app logo + biometric icon
- Auto-triggers Face ID / Touch ID on appear
- "Use password" fallback → redirects to WelcomeScreen with session cleared

**States:**
- Prompting biometric
- Failed (show retry button)
- Fallback triggered

---

### AppRootView (Router)
```swift
struct AppRootView: View {
    @State private var authVM = AuthViewModel(...)

    var body: some View {
        switch authVM.state {
        case .loading:          LoadingView()
        case .unauthenticated:  WelcomeScreen(vm: authVM)
        case .locked:           LockScreen(vm: authVM)
        case .authenticated:    HomeScreen()
        case .error(let msg):   ErrorView(message: msg)
        }
    }
}
```

---

## 10. Third-Party Dependencies

| Dependency | Purpose | Added via |
|---|---|---|
| `GoogleSignIn-iOS` | Google Sign-In SDK | Swift Package Manager |
| None for Apple | Native `AuthenticationServices` | Built-in |

SPM URL: `https://github.com/google/GoogleSignIn-iOS`

---

## 11. Edge Cases

| Case | Handling |
|---|---|
| User denies Face ID permission | Show "Enable in Settings" prompt |
| Apple returns no email (repeat sign-in) | Use cached email from Keychain |
| Google sign-in cancelled | Return to WelcomeScreen, no error shown |
| Keychain read failure | Treat as unauthenticated, log error |
| App deleted + reinstalled | Keychain persists on device — check for orphaned session |

---

## 12. V2 Migration Notes

When backend is added:
- Swap `LocalAuthRepository` → `RemoteAuthRepository` (same protocol)
- `AuthSession` gains `accessToken` + `refreshToken` fields
- Add `AuthInterceptor` to network layer
- Add token refresh logic in `RemoteAuthRepository`
- **Zero changes to ViewModels or UI**

---

## 13. File Structure

```
Features/Auth/
├── Models/
│   ├── User.swift
│   ├── AuthSession.swift
│   └── AuthProvider.swift
├── Repository/
│   ├── AuthRepository.swift          # Protocol
│   └── LocalAuthRepository.swift     # V1 impl
├── Services/
│   ├── KeychainService.swift
│   ├── BiometricService.swift
│   └── IDPAuthService.swift
├── ViewModels/
│   └── AuthViewModel.swift
└── Views/
    ├── AppRootView.swift
    ├── WelcomeScreen.swift
    └── LockScreen.swift
```

---

## 14. Acceptance Criteria

- [ ] New user can sign in with Apple and land on HomeScreen
- [ ] New user can sign in with Google and land on HomeScreen
- [ ] Returning user sees LockScreen on relaunch
- [ ] Face ID success navigates to HomeScreen
- [ ] Face ID failure shows retry + fallback option
- [ ] Sign out clears Keychain and returns to WelcomeScreen
- [ ] App reinstall with existing Keychain handles gracefully
