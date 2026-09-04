import XCTest
import LocalAuthentication
import SwiftUI
@testable import SavingsTrackerCore

/// Mock provider for testing LocalAuthentication flows deterministically.
@MainActor
final class MockLocalAuthProvider: LocalAuthenticationProviding {
    var isBiometryAvailable: Bool = true
    var isPasscodeAvailable: Bool = true
    var biometryType: LABiometryType = .faceID
    var biometryDisplayName: String = "Face ID"
    var biometryIconName: String = "faceid"
    var isAuthenticated: Bool = false
    var isAuthenticating: Bool = false
    var authenticationError: String? = nil

    var shouldAuthenticateSucceed: Bool = true
    var authenticateCallCount: Int = 0
    var lockSessionCallCount: Int = 0

    func checkAvailability() {}

    func authenticate(reason: String) async -> Bool {
        authenticateCallCount += 1
        isAuthenticated = shouldAuthenticateSucceed
        if !shouldAuthenticateSucceed {
            authenticationError = "User cancelled authentication"
        } else {
            authenticationError = nil
        }
        return shouldAuthenticateSucceed
    }

    func lockSession() {
        lockSessionCallCount += 1
        isAuthenticated = false
    }
}

@MainActor
final class AppLockTests: XCTestCase {

    private var mockAuth: MockLocalAuthProvider!
    private var testUserDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "com.savingstracker.tests.applock.\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: suiteName)!
        mockAuth = MockLocalAuthProvider()
    }

    override func tearDown() async throws {
        testUserDefaults.removePersistentDomain(forName: suiteName)
        mockAuth = nil
        try await super.tearDown()
    }

    func testAppLockInitialStateWhenDisabled() {
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        XCTAssertFalse(manager.isAppLockEnabled)
        XCTAssertFalse(manager.isLocked)
    }

    func testAppLockInitialStateWhenEnabled() {
        testUserDefaults.set(true, forKey: "com.savingstracker.app.app_lock_enabled")
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        XCTAssertTrue(manager.isAppLockEnabled)
        XCTAssertTrue(manager.isLocked)
    }

    func testPreflightToggleAppLockSuccess() async {
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        mockAuth.shouldAuthenticateSucceed = true

        let toggledOn = await manager.preflightToggleAppLock(to: true)
        XCTAssertTrue(toggledOn)
        XCTAssertTrue(manager.isAppLockEnabled)
        XCTAssertEqual(mockAuth.authenticateCallCount, 1)

        let toggledOff = await manager.preflightToggleAppLock(to: false)
        XCTAssertTrue(toggledOff)
        XCTAssertFalse(manager.isAppLockEnabled)
        XCTAssertFalse(manager.isLocked)
    }

    func testPreflightToggleAppLockFailureProtectsState() async {
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        mockAuth.shouldAuthenticateSucceed = false

        let toggled = await manager.preflightToggleAppLock(to: true)
        XCTAssertFalse(toggled)
        XCTAssertFalse(manager.isAppLockEnabled)
        XCTAssertFalse(manager.isLocked)
    }

    func testImmediateLockOnBackgroundTransition() async {
        testUserDefaults.set(true, forKey: "com.savingstracker.app.app_lock_enabled")
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        manager.autoLockTimeout = .immediate

        // Unlock first
        mockAuth.shouldAuthenticateSucceed = true
        _ = await manager.requestUnlock()
        XCTAssertFalse(manager.isLocked)

        // Simulate entering background
        manager.handleScenePhaseChange(.background)
        XCTAssertTrue(manager.isLocked)
        XCTAssertNotNil(manager.lastBackgroundDate)
    }

    func testGracePeriodTimeoutEvaluation() async {
        testUserDefaults.set(true, forKey: "com.savingstracker.app.app_lock_enabled")
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        manager.autoLockTimeout = .oneMinute

        // Unlock initially
        mockAuth.shouldAuthenticateSucceed = true
        _ = await manager.requestUnlock()
        XCTAssertFalse(manager.isLocked)

        // Simulate background transition
        manager.handleScenePhaseChange(.background)
        // Background with 1 min timeout should not lock immediately
        XCTAssertFalse(manager.isLocked)

        // Evaluate return to active when under 60 seconds
        manager.evaluateLockStateOnActive()
        XCTAssertFalse(manager.isLocked)
    }

    func testDeepLinkInterceptionWhileLocked() {
        testUserDefaults.set(true, forKey: "com.savingstracker.app.app_lock_enabled")
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        XCTAssertTrue(manager.isLocked)

        let testURL = URL(string: "savingstracker://record/2026-09")!
        let canOpenImmediately = manager.handleDeepLink(testURL)

        // Must NOT open immediately while locked
        XCTAssertFalse(canOpenImmediately)
        XCTAssertEqual(manager.pendingDeepLinkURL, testURL)
    }

    func testDeepLinkAllowedWhenUnlocked() {
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        XCTAssertFalse(manager.isLocked)

        let testURL = URL(string: "savingstracker://record/2026-09")!
        let canOpenImmediately = manager.handleDeepLink(testURL)

        XCTAssertTrue(canOpenImmediately)
        XCTAssertNil(manager.pendingDeepLinkURL)
    }

    func testSuccessfulUnlockReleasesPendingDeepLink() async {
        testUserDefaults.set(true, forKey: "com.savingstracker.app.app_lock_enabled")
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        mockAuth.shouldAuthenticateSucceed = true

        let testURL = URL(string: "savingstracker://deposit/emergency")!
        manager.handleDeepLink(testURL)
        XCTAssertEqual(manager.pendingDeepLinkURL, testURL)

        let unlocked = await manager.requestUnlock()
        XCTAssertTrue(unlocked)
        XCTAssertFalse(manager.isLocked)
        XCTAssertNil(manager.pendingDeepLinkURL)
    }

    func testAuthenticationCancellationKeepsAppLocked() async {
        testUserDefaults.set(true, forKey: "com.savingstracker.app.app_lock_enabled")
        let manager = AppLockManager(biometricManager: mockAuth, userDefaults: testUserDefaults)
        mockAuth.shouldAuthenticateSucceed = false

        let unlocked = await manager.requestUnlock()
        XCTAssertFalse(unlocked)
        XCTAssertTrue(manager.isLocked)
    }
}
