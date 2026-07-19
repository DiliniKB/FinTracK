# Settings Screen Spec — V1
> Finance Tracker iOS App | Spec-Driven Development | Version 1.0

---

## 1. Overview

### Purpose
Settings consolidates app configuration and account management into a single screen, replacing the standalone Categories tab. Users access it infrequently — it should be fast to navigate and never interrupt the core finance workflow.

### Scope
- Move Categories out of the tab bar into Settings
- Notifications preference (budget alerts)
- Security preference (biometric lock)
- Account section (sign out)
- About section (app version)

### Out of Scope
- Cloud sync / backup settings (V2)
- Currency preference (V2)
- Data export (V2)
- Theme / appearance (V2)

---

## 2. Tab Bar Change

**Before:**
```
Dashboard | Transactions | Budgets | Categories
```

**After:**
```
Dashboard | Transactions | Budgets | Settings
```

- `CategoriesScreen` is no longer a root tab
- It is pushed via `NavigationLink` from Settings
- No changes to `CategoriesScreen` itself

---

## 3. Screen Layout

```
┌─────────────────────────────────────┐
│  Settings               (nav title) │
├─────────────────────────────────────┤
│  MANAGE                             │
│  ┌───────────────────────────────┐  │
│  │  ❯  Categories               │  │  → pushes CategoriesScreen
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  PREFERENCES                        │
│  ┌───────────────────────────────┐  │
│  │  🔔  Budget Alerts     [on]  │  │  → toggle (UNUserNotification)
│  │  ─────────────────────────── │  │
│  │  🔒  Face ID / Touch ID [on] │  │  → toggle (biometric lock)
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  ACCOUNT                            │
│  ┌───────────────────────────────┐  │
│  │  👤  dilinibandara24@gmail…  │  │  → read-only, shows signed-in email
│  │  ─────────────────────────── │  │
│  │  Sign Out                    │  │  → destructive, confirmation alert
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  ABOUT                              │
│  ┌───────────────────────────────┐  │
│  │  FinTrack          v1.0.0    │  │  → read-only
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 4. Sections

### 4.1 Manage
| Row | Action |
|-----|--------|
| Categories | `NavigationLink` → pushes `CategoriesScreen` |

### 4.2 Preferences
| Row | Type | Behaviour |
|-----|------|-----------|
| Budget Alerts | `Toggle` | Calls `UNUserNotificationCenter.requestAuthorization` on first enable; disables if user denies permission in system settings |
| Face ID / Touch ID | `Toggle` | Reads `BiometricService.biometricType` for label; persists to `AuthRepository` / `KeychainService` |

- Label for biometric row reads from `BiometricService.biometricType` → "Face ID", "Touch ID", or hidden if `isAvailable == false`
- Both toggles read/write `UserDefaults` keys: `budgetAlertsEnabled`, `biometricLockEnabled`

### 4.3 Account
| Row | Type | Behaviour |
|-----|------|-----------|
| Email | Read-only label | Shows current user's email or provider badge (Apple / Google) |
| Sign Out | Destructive button | Confirmation alert → calls `AuthViewModel.signOut()` |

### 4.4 About
| Row | Value |
|-----|-------|
| App name + version | Read from `Bundle.main.infoDictionary` — `CFBundleShortVersionString` |

---

## 5. ViewModel

```swift
@Observable
@MainActor
final class SettingsViewModel {

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

    var showSignOutAlert = false

    private let authViewModel: AuthViewModel
    private let biometricService: any BiometricService

    var biometricLabel: String { biometricService.biometricType == .faceID ? "Face ID" : "Touch ID" }
    var biometricAvailable: Bool { biometricService.isAvailable }
    var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—" }

    func signOut() { try? authViewModel.signOut() }
    private func requestNotificationPermission() async { ... }
}
```

---

## 6. File Structure

```
Features/Settings/
├── ViewModels/
│   └── SettingsViewModel.swift
└── Views/
    └── SettingsScreen.swift
```

`CategoriesScreen` stays in `Features/Categories/Views/` — only its tab entry is removed.

---

## 7. AppRootView Change

```swift
// Remove:
CategoriesScreen()
    .tabItem { Label("Categories", systemImage: "tag.fill") }

// Add:
SettingsScreen(authVM: authViewModel)
    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
```

`SettingsScreen` receives `authViewModel` from `AppRootView` (already available there).

---

## 8. Acceptance Criteria

- [ ] Categories tab removed; gear icon replaces it
- [ ] Categories screen accessible via Settings → Categories row
- [ ] Budget Alerts toggle reflects actual notification permission state
- [ ] Biometric row hidden when device has no biometric hardware
- [ ] Sign Out shows confirmation alert before acting
- [ ] Sign Out navigates user to WelcomeScreen
- [ ] App version displays correctly from Bundle
- [ ] All rows use standard `List` / `Form` inset grouped style

---

## 9. V2 Notes
- Data export (CSV / JSON)
- Default currency selector
- iCloud sync toggle
- Appearance: light / dark / system
