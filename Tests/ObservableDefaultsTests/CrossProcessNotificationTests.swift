//
//  CrossProcessNotificationTests.swift
//  ObservableDefaults
//
//  Tests for cross-process notification functionality with limitToInstance parameter
//

import Testing
@testable import ObservableDefaults
import Foundation

@ObservableDefaults(
    suiteName: "test.crossprocess.suite1",
    prefix: "app_",
    limitToInstance: false  // Enable cross-process notifications
)
class SettingsWithPrefix {
    var userName: String = "InitialUser"
    var counter: Int = 0
}

@ObservableDefaults(
    suiteName: "test.crossprocess.suite2",
    limitToInstance: false  // Enable cross-process notifications
)
class SettingsNoPrefix {
    var userName: String = "OtherUser"
    var counter: Int = 100
}

@Suite("Cross-Process Notification Tests", .serialized)
struct CrossProcessNotificationTests {

    func cleanupUserDefaults() {
        // Clean up UserDefaults before each test
        if let suite = UserDefaults(suiteName: "test.crossprocess.suite1") {
            for key in suite.dictionaryRepresentation().keys {
                suite.removeObject(forKey: key)
            }
            suite.synchronize()
        }
        if let suite = UserDefaults(suiteName: "test.crossprocess.suite2") {
            for key in suite.dictionaryRepresentation().keys {
                suite.removeObject(forKey: key)
            }
            suite.synchronize()
        }
    }

    @Test("Only receive notifications for matching suite when limitToInstance is false")
    func testCrossProcessNotificationFiltering() async throws {
        cleanupUserDefaults()

        // Create instances
        let settingsWithPrefix = SettingsWithPrefix()
        let settingsNoPrefix = SettingsNoPrefix()

        // Verify initial values
        #expect(settingsWithPrefix.userName == "InitialUser")
        #expect(settingsWithPrefix.counter == 0)
        #expect(settingsNoPrefix.userName == "OtherUser")
        #expect(settingsNoPrefix.counter == 100)

        // Modify the suite WITH prefix directly through UserDefaults
        let suiteWithPrefix = UserDefaults(suiteName: "test.crossprocess.suite1")!
        suiteWithPrefix.set("UpdatedUser", forKey: "app_userName")  // Has prefix
        suiteWithPrefix.set(42, forKey: "app_counter")  // Has prefix

        // Post notification to simulate external change
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)

        // Allow time for notification processing
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Values should be updated automatically due to limitToInstance: false
        #expect(settingsWithPrefix.userName == "UpdatedUser")
        #expect(settingsWithPrefix.counter == 42)

        // Now modify the suite WITHOUT prefix (should NOT affect settingsWithPrefix)
        let suiteNoPrefix = UserDefaults(suiteName: "test.crossprocess.suite2")!
        suiteNoPrefix.set("ChangedOtherUser", forKey: "userName")  // No prefix
        suiteNoPrefix.set(200, forKey: "counter")  // No prefix

        // Post notification to simulate external change
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)

        // Allow time for notification processing
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // settingsWithPrefix should remain unchanged (different suite, different keys)
        #expect(settingsWithPrefix.userName == "UpdatedUser")  // Should stay the same
        #expect(settingsWithPrefix.counter == 42)  // Should stay the same

        // settingsNoPrefix should have new values when accessed
        #expect(settingsNoPrefix.userName == "ChangedOtherUser")
        #expect(settingsNoPrefix.counter == 200)
    }

    @Test("Verify prefix isolation between suites")
    func testPrefixIsolation() async throws {
        cleanupUserDefaults()

        let settingsWithPrefix = SettingsWithPrefix()
        let settingsNoPrefix = SettingsNoPrefix()

        // Set values through the instances
        settingsWithPrefix.userName = "PrefixUser"
        settingsNoPrefix.userName = "NoPrefixUser"

        // Check UserDefaults directly to verify keys
        let suiteWithPrefix = UserDefaults(suiteName: "test.crossprocess.suite1")!
        let suiteNoPrefix = UserDefaults(suiteName: "test.crossprocess.suite2")!

        // Keys should be different due to prefix
        #expect(suiteWithPrefix.string(forKey: "app_userName") == "PrefixUser")
        #expect(suiteWithPrefix.string(forKey: "userName") == nil)  // No key without prefix

        #expect(suiteNoPrefix.string(forKey: "userName") == "NoPrefixUser")
        #expect(suiteNoPrefix.string(forKey: "app_userName") == nil)  // No key with prefix
    }
}