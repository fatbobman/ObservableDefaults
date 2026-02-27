//
//  ExternalChangeEqualityTests.swift
//  ObservableDefaults
//
//  Tests that the external UserDefaults change notification handler
//  only triggers observation mutations when values actually change.
//

import Foundation
import ObservableDefaults
import Observation
import Testing

@Suite("External Change Equality Check", .serialized)
struct ExternalChangeEqualityTests {
    private func makeUserDefaults(testName: String = #function) -> UserDefaults {
        UserDefaults.getTestInstance(
            suiteName: "ExternalChangeEqualityTests.\(testName).\(UUID().uuidString)")
    }

    @Test("Unrelated property not notified when another property changes externally")
    func unrelatedPropertyNotNotified() {
        let userDefaults = makeUserDefaults()
        let model = MockModel(userDefaults: userDefaults)

        // Track age - expect NO mutation when only name changes
        tracking(model, \.age, .userDefaults, false)
        userDefaults.set("NewName", forKey: "name")
    }

    @Test("Same value write does not notify for backed property")
    func sameValueWriteNotNotified() {
        let userDefaults = makeUserDefaults()
        let model = MockModel(userDefaults: userDefaults)

        // Track name - expect NO mutation when writing the same value
        tracking(model, \.name, .userDefaults, false)
        userDefaults.set("Test", forKey: "name")
    }

    @MainActor
    @Test("MainActor unrelated property not notified when another property changes externally")
    func mainActorUnrelatedPropertyNotNotified() async {
        let userDefaults = makeUserDefaults()
        let model = MockModelMainActor(userDefaults: userDefaults)

        // Track count - expect NO mutation when only name changes
        tracking(model, \.count, .userDefaults, false)
        userDefaults.set("ExternalMainActorName", forKey: "name")

        // MainActor observer path uses .main queue
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.name == "ExternalMainActorName")
        #expect(model.count == 0)
    }

    @MainActor
    @Test("MainActor same value write does not notify for backed property")
    func mainActorSameValueWriteNotNotified() async {
        let userDefaults = makeUserDefaults()
        let model = MockModelMainActor(userDefaults: userDefaults)

        // Track name - expect NO mutation when writing the same value
        tracking(model, \.name, .userDefaults, false)
        userDefaults.set("Test", forKey: "name")

        // MainActor observer path uses .main queue
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.name == "Test")
    }

    // MARK: - Removing key (setting to nil) should trigger mutation

    @Test("Removing key from UserDefaults triggers mutation back to default value")
    func removingKeyTriggersMutation() {
        let userDefaults = makeUserDefaults()
        let model = MockModel(userDefaults: userDefaults)

        // Set a non-default value first
        model.name = "Changed"

        // Removing the key should trigger mutation (value reverts to default "Test")
        tracking(model, \.name, .userDefaults)
        userDefaults.removeObject(forKey: "name")
        #expect(model.name == "Test")
    }

    @Test("Optional property: removing key triggers mutation back to nil")
    func optionalRemovingKeyTriggersMutation() {
        let userDefaults = makeUserDefaults()
        let model = MockModelOptional(userDefaults: userDefaults)

        // Set a non-nil value first
        model.optionalName = "Hello"

        // Removing the key should trigger mutation (value reverts to nil)
        tracking(model, \.optionalName, .userDefaults)
        userDefaults.removeObject(forKey: "optionalName")
        #expect(model.optionalName == nil)
    }

    @Test("Removing key falls back to registered default before model default")
    func removingKeyFallsBackToRegisteredDefault() {
        let userDefaults = makeUserDefaults()
        userDefaults.register(defaults: ["name": "Registered"])
        let model = MockModel(userDefaults: userDefaults)

        model.name = "Changed"

        tracking(model, \.name, .userDefaults)
        userDefaults.removeObject(forKey: "name")
        #expect(model.name == "Registered")
    }

    @Test("Optional property falls back to registered default before nil")
    func optionalRemovingKeyFallsBackToRegisteredDefault() {
        let userDefaults = makeUserDefaults()
        userDefaults.register(defaults: ["optionalName": "RegisteredOptional"])
        let model = MockModelOptional(userDefaults: userDefaults)

        model.optionalName = "Hello"

        tracking(model, \.optionalName, .userDefaults)
        userDefaults.removeObject(forKey: "optionalName")
        #expect(model.optionalName == "RegisteredOptional")
    }

    @MainActor
    @Test("MainActor removing key falls back to registered default")
    func mainActorRemovingKeyFallsBackToRegisteredDefault() async {
        let userDefaults = makeUserDefaults()
        userDefaults.register(defaults: ["name": "MainActorRegistered"])
        let model = MockModelMainActor(userDefaults: userDefaults)

        model.name = "Changed"

        tracking(model, \.name, .userDefaults)
        userDefaults.removeObject(forKey: "name")

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.name == "MainActorRegistered")
    }
}
