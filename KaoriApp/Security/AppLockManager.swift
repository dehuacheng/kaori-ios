import Foundation
import LocalAuthentication

@Observable
class AppLockManager {
    var isLocked: Bool
    private(set) var didEnterBackground = false

    var isAppLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isAppLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isAppLockEnabled") }
    }

    init() {
        // Start locked if app lock is enabled
        self.isLocked = UserDefaults.standard.bool(forKey: "isAppLockEnabled")
    }

    // MARK: - Lifecycle

    func appDidEnterBackground() {
        didEnterBackground = true
    }

    func appWillEnterForeground() {
        guard isAppLockEnabled, didEnterBackground else { return }
        didEnterBackground = false
        isLocked = true
    }

    // MARK: - Authentication

    @MainActor
    func authenticate() async {
        let context = LAContext()
        context.localizedCancelTitle = nil

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: NSLocalizedString("Unlock Kaori", comment: "")
            )
            if success {
                isLocked = false
            }
        } catch {
            // User cancelled or auth failed — stay locked
        }
    }

    /// Verify the user can authenticate before enabling app lock.
    @MainActor
    func authenticateToEnable() async -> Bool {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: NSLocalizedString("Enable App Lock", comment: "")
            )
            return success
        } catch {
            return false
        }
    }

    // MARK: - Biometry Info

    var biometryLabel: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Passcode"
        }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Passcode"
        @unknown default: return "Biometrics"
        }
    }

    var biometrySystemImage: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "lock.fill"
        }
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.fill"
        @unknown default: return "lock.fill"
        }
    }
}
