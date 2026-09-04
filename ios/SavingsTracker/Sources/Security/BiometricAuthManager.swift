import Foundation
import LocalAuthentication

/// Protocol defining the local authentication interface for production and test isolation.
@MainActor
public protocol LocalAuthenticationProviding: AnyObject {
    var isBiometryAvailable: Bool { get }
    var isPasscodeAvailable: Bool { get }
    var biometryType: LABiometryType { get }
    var biometryDisplayName: String { get }
    var biometryIconName: String { get }
    var isAuthenticated: Bool { get }
    var isAuthenticating: Bool { get }
    var authenticationError: String? { get }

    func checkAvailability()
    func authenticate(reason: String) async -> Bool
    func lockSession()
}

/// Manages Biometric (Face ID / Touch ID / Optic ID) and Passcode authentication flows with LocalAuthentication.
/// Strictly enforces Secure Enclave authentication and delegates all credential verification to iOS.
/// NEVER stores, accesses, or processes user biometrics or passcodes directly.
@MainActor
public final class BiometricAuthManager: ObservableObject, LocalAuthenticationProviding {

    public static let shared = BiometricAuthManager()

    @Published public private(set) var isBiometryAvailable: Bool = false
    @Published public private(set) var isPasscodeAvailable: Bool = false
    @Published public private(set) var biometryType: LABiometryType = .none
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var isAuthenticating: Bool = false
    @Published public private(set) var authenticationError: String?

    /// Enrolled biometric domain state signature. Changes if a new fingerprint/face is enrolled.
    private var lastEnrolledDomainState: Data?

    public init() {
        checkAvailability()
    }

    /// Evaluates device hardware capabilities for Biometrics (Face ID / Touch ID) and Device Passcode.
    public func checkAvailability() {
        let context = LAContext()
        var bioError: NSError?
        var passcodeError: NSError?

        // 1. Check biometrics (Face ID / Touch ID / Optic ID)
        self.isBiometryAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &bioError)
        self.biometryType = context.biometryType

        // Store enrolled domain state to detect subsequent enrollment tampering/additions
        if self.isBiometryAvailable {
            self.lastEnrolledDomainState = context.evaluatedPolicyDomainState
        }

        // 2. Check device passcode fallback availability
        self.isPasscodeAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &passcodeError)

        if let bioError = bioError {
            SecureLogger.security.debug("Biometrics unavailable or not enrolled: \(bioError.localizedDescription, privacy: .public)")
        }
        if let passcodeError = passcodeError {
            SecureLogger.security.warning("Device passcode is not configured: \(passcodeError.localizedDescription, privacy: .public)")
        }
    }

    /// User-friendly name of the available biometric or authentication modality.
    public var biometryDisplayName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return isPasscodeAvailable ? "Passcode" : "Authentication"
        @unknown default:
            return "Biometrics"
        }
    }

    /// SF Symbol icon name appropriate for the available hardware.
    public var biometryIconName: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return isPasscodeAvailable ? "lock.fill" : "lock.shield.fill"
        @unknown default:
            return "lock.shield.fill"
        }
    }

    /// Authenticates the user with Face ID / Touch ID, falling back to device passcode if required.
    /// - Parameter reason: User-facing prompt string displayed on the system alert.
    /// - Returns: Boolean indicating whether authentication succeeded.
    public func authenticate(reason: String = "Authenticate to unlock your Savings Vault") async -> Bool {
        // Prevent concurrent overlapping authentication prompts
        guard !isAuthenticating else {
            SecureLogger.security.debug("Authentication request dropped: prompt already presented.")
            return false
        }

        self.isAuthenticating = true
        defer { self.isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"

        var evalError: NSError?
        // System policy: Biometrics first, falling back to device passcode
        let policy: LAPolicy = .deviceOwnerAuthentication

        guard context.canEvaluatePolicy(policy, error: &evalError) else {
            let errorMsg = evalError?.localizedDescription ?? "Authentication unavailable. Please ensure a device passcode is set."
            self.authenticationError = errorMsg
            SecureLogger.security.error("Authentication policy unavailable: \(errorMsg, privacy: .public)")
            return false
        }

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            self.isAuthenticated = success
            if success {
                self.authenticationError = nil

                // Detect if enrollment state changed since last session
                if let currentState = context.evaluatedPolicyDomainState,
                   let previousState = self.lastEnrolledDomainState,
                   currentState != previousState {
                    SecureLogger.security.notice("Biometric domain state changed (e.g. new fingerprint or face enrolled).")
                    self.lastEnrolledDomainState = currentState
                }

                SecureLogger.security.info("Local authentication succeeded via \(self.biometryDisplayName, privacy: .public).")
            }
            return success
        } catch let authError as LAError {
            self.isAuthenticated = false
            switch authError.code {
            case .userCancel:
                self.authenticationError = "Authentication cancelled."
                SecureLogger.security.debug("User cancelled local authentication prompt.")
            case .userFallback:
                self.authenticationError = "Device passcode fallback requested."
                SecureLogger.security.debug("User selected passcode fallback.")
            case .biometryLockout:
                self.authenticationError = "Biometrics locked due to failed attempts. Use device passcode."
                SecureLogger.security.notice("Biometrics locked out.")
            case .passcodeNotSet:
                self.authenticationError = "No device passcode is configured in iOS Settings."
                SecureLogger.security.error("Device passcode not set.")
            default:
                self.authenticationError = authError.localizedDescription
                SecureLogger.security.notice("Authentication declined: code \(authError.errorCode, privacy: .public)")
            }
            return false
        } catch {
            self.isAuthenticated = false
            self.authenticationError = error.localizedDescription
            SecureLogger.security.error("Unexpected error during authentication: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Locks the app session immediately.
    public func lockSession() {
        self.isAuthenticated = false
        SecureLogger.security.info("User session locked.")
    }
}
