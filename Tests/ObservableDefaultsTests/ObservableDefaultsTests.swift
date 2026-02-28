//
// ObservableDefaultsTests.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
import ObservableDefaults
import Observation
import Testing

@Suite("ObservableDefaults")
struct ObservableDefaultsTests {
    @Test("Property Observable")
    func propertyObservable() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)
        tracking(model, \.name, .direct)
        model.name = "Test2"

        tracking(model, \.name, .userDefaults)
        userDefaults.set("Test3", forKey: "name")
    }

    @Test("Ignore External Changes")
    func ignoreExternalChanges() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults, ignoreExternalChanges: true)
        tracking(model, \.name, .direct)
        model.name = "Test2"

        tracking(model, \.name, .userDefaults, false)
        userDefaults.set("Test3", forKey: "name")
        #expect(
            model.name == "Test3",
            "name should not be observable by setting value by UserDefaults")
    }

    @Test("Ignore External Changes for specific properties")
    func ignoreExternalChangesForSpecificProperties() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(
            userDefaults: userDefaults,
            ignoredKeyPathsForExternalUpdates: [\.name])
        tracking(model, \.name, .direct)
        model.name = "Test2"

        tracking(model, \.name, .userDefaults, false)
        userDefaults.set("Test3", forKey: "name")
        #expect(
            model.name == "Test3",
            "name should not be observable by setting value by UserDefaults")
    }

    @Test("Igonre Other UserDefaults Changes")
    func ignoreOtherUserDefaultsChanges() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let userDefaults2 = UserDefaults.getTestInstance(suiteName: #function + "2")
        let model = MockModel(userDefaults: userDefaults)
        tracking(model, \.name, .userDefaults)
        userDefaults2.set("Test1", forKey: "name")
        #expect(
            model.name == "Test",
            "name should only be observable by the same UserDefaults")
        userDefaults.set("Test2", forKey: "name")
        #expect(
            model.name == "Test2",
            "name should be observable by setting value by the same UserDefaults")
    }

    @Test("Prefix")
    func prefix() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults, prefix: "test_")
        tracking(model, \.name, .userDefaults)
        userDefaults.set("Test1", forKey: "test_name")
        #expect(model.name == "Test1", "name should be observable by setting value by UserDefaults")
    }

    @Test("Observable Only")
    func observableOnly() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)
        tracking(model, \.observableOnly, .direct)
        userDefaults.set("Test3", forKey: "observableOnly")
        #expect(
            model.observableOnly == "ObservableOnly",
            "observableOnly should be observable by setting value by UserDefaults")

        tracking(model, \.observableOnly, .direct)
        model.observableOnly = "Test2"
        #expect(
            model.observableOnly == "Test2",
            "observableOnly should be observable by setting value directly")
    }

    @Test("Ignore Macro")
    func ignoreMacro() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)
        tracking(model, \.ignore, .direct, false)
        model.ignore = "Test2"
        #expect(
            model.ignore == "Test2",
            "ignore should not be observable by setting value directly")
    }

    @Test("Observe First")
    func observeFirst() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelObserveFirst(userDefaults: userDefaults)
        tracking(model, \.name, .userDefaults)
        userDefaults.set("Test1", forKey: "name")
        #expect(model.name == "Test1", "name should be observable by setting value by UserDefaults")

        tracking(model, \.observableOnly, .direct)
        model.observableOnly = "Test2"
        #expect(
            model.observableOnly == "Test2",
            "observableOnly should be observable by setting value directly")
    }

    @Test("Observe First ObservableOnly supports WillSet and DidSet")
    func observeFirstObservableOnlySupportsWillSetAndDidSet() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelObserveFirstWithObservers(userDefaults: userDefaults)

        model.observableOnly = "Test2"
        #expect(
            model.setResult == ["willSet: Test2", "didSet: ObservableOnly"],
            "willSet/didSet should run for observeFirst observable-only properties")
    }

    @Test("Observe First ObservableOnly supports WillSet and DidSet via _modify")
    func observeFirstObservableOnlySupportsWillSetAndDidSetViaModify() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelObserveFirstWithObservers(userDefaults: userDefaults)

        model.observableCollection.append("Test2")
        #expect(model.setResult.count == 2)
        #expect(model.setResult.first == "willSet collection: [\"ObservableOnly\", \"Test2\"]")
        #expect(model.setResult.last == "didSet collection: [\"ObservableOnly\"]")
    }

    @Test("Specify Key Name")
    func specifyKeyName() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelKeyName(userDefaults: userDefaults)
        tracking(model, \.renameByBackedKey, .userDefaults)
        userDefaults.set("Test1", forKey: "rename-by-backed-key")
        #expect(
            model.renameByBackedKey == "Test1",
            "renameByBackedKey should be observable by setting value by UserDefaults")

        tracking(model, \.renameByDefaultsKey, .userDefaults)
        userDefaults.set("Test2", forKey: "rename-by-defaults-key")
        #expect(
            model.renameByDefaultsKey == "Test2",
            "renameByDefaultsKey should be observable by setting value by UserDefaults")

        tracking(model, \.mixKey, .userDefaults)
        userDefaults.set("Test3", forKey: "mix-key-backed-key")
        #expect(
            model.mixKey == "Test3",
            "mixKey should be observable by setting value by UserDefaults")
    }

    @Test("Ignore Same Value Set for Backed Property")
    func ignoreSameValueForBackedProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        tracking(model, \.name, .direct, false)
        model.name = "Test"  // same value
    }

    @Test("Ignore Same Value Set for Observable Only Property")
    func ignoreSameValueForObservableOnlyProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        tracking(model, \.observableOnly, .direct, false)
        model.observableOnly = "ObservableOnly"  // same value
    }

    @Test("WillSet and DidSet are not supported for Backed Property")
    func willSetAndDidSetAreNotSupportedForBackedProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        model.name = "test1"
        #expect(model.setResult.isEmpty, "willSet/didSet should not run for backed properties")
    }

    @Test("WillSet and DidSet for Observable Only Property")
    func willSetAndDidSetForObservableOnlyProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        tracking(model, \.setResult, .direct)
        model.observableOnly = "test1"
        #expect(
            model.setResult == ["willSet: test1", "didSet: ObservableOnly"],
            "setResult should be observable by setting value directly")
    }

    @Test("WillSet and DidSet for Ignore Property")
    func willSetAndDidSetForIgnoreProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        tracking(model, \.setResult, .direct)
        model.ignore = "test1"
        #expect(model.setResult == ["willSet: test1", "didSet: Ignore"])
    }

    @Test("Default value never change after initialization even remove from UserDefaults")
    func defaultValueNeverChange() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)
        model.name = "Test2"
        userDefaults.removeObject(forKey: "name")
        #expect(model.name == "Test", "initial value never change after initialization")
    }

    @Test(
        "Default value never change after initialization even remove from UserDefaults, default value from initializer")
    func defaultValueNeverChangeFromInitializer() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelAutoInitFalse(name: "Test5", defaults: userDefaults)
        // model.name = "Test6"
        #expect(model.name == "Test5", "initial value never change after initialization")
    }

    @Test("Optional Property Support")
    func optionalPropertySupport() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelOptional(userDefaults: userDefaults)

        // Test initial values - these should match the default values defined in MockModelOptional
        #expect(model.optionalName == nil, "optionalName should start as nil")
        #expect(model.optionalAge == 25, "optionalAge should start as 25")
        #expect(model.optionalWithoutInitializer == nil, "optionalWithoutInitializer should start as nil")
        #expect(model.optionalWithCustomKey == true, "optionalWithCustomKey should start as true")
        #expect(model.name == nil, "name should start as nil")

        // Test setting values
        tracking(model, \.optionalName, .direct)
        model.optionalName = "TestName"
        #expect(model.optionalName == "TestName", "optionalName should be set to TestName")

        tracking(model, \.optionalAge, .direct)
        model.optionalAge = nil
        #expect(model.optionalAge == 25, "optionalAge should revert to default value (25) when set to nil")

        tracking(model, \.optionalWithoutInitializer, .direct)
        model.optionalWithoutInitializer = 3.14
        #expect(model.optionalWithoutInitializer == 3.14, "optionalWithoutInitializer should be set to 3.14")

        // Test external UserDefaults changes
        tracking(model, \.optionalName, .userDefaults)
        userDefaults.set("ExternalName", forKey: "optionalName")
        #expect(model.optionalName == "ExternalName", "optionalName should be updated from UserDefaults")

        tracking(model, \.optionalWithCustomKey, .userDefaults)
        userDefaults.set(false, forKey: "custom-optional-key")
        #expect(model.optionalWithCustomKey == false, "optionalWithCustomKey should be updated from UserDefaults with custom key")

        // Test removing values (should revert to default)
        userDefaults.removeObject(forKey: "optionalName")
        #expect(model.optionalName == nil, "optionalName should revert to default (nil) when removed from UserDefaults")

        userDefaults.removeObject(forKey: "optionalAge")
        #expect(model.optionalAge == 25, "optionalAge should revert to default (25) when removed from UserDefaults")

        userDefaults.removeObject(forKey: "optionalWithoutInitializer")
        #expect(model.optionalWithoutInitializer == nil, "optionalWithoutInitializer should revert to default (nil) when removed from UserDefaults")
    }

    @Test("Codable Type with Static Properties Support")
    func codableTypeWithStaticPropertiesSupport() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelCodable(userDefaults: userDefaults)

        // Test initial values with static properties
        #expect(model.style == .style1, "style should start as .style1")
        #expect(model.explicitStyle == .style2, "explicitStyle should start as .style2")

        // Test setting values
        tracking(model, \.style, .direct)
        model.style = .style3
        #expect(model.style == .style3, "style should be set to .style3")

        tracking(model, \.explicitStyle, .direct)
        model.explicitStyle = .style1
        #expect(model.explicitStyle == .style1, "explicitStyle should be set to .style1")

        // Test external UserDefaults changes with Codable types
        tracking(model, \.style, .userDefaults)
        let style2Data = try! JSONEncoder().encode(FontStyle.style2)
        userDefaults.set(style2Data, forKey: "style")
        #expect(model.style == .style2, "style should be updated from UserDefaults")

        // Test removing values (should revert to default)
        userDefaults.removeObject(forKey: "style")
        #expect(model.style == .style1, "style should revert to default (.style1) when removed from UserDefaults")

        userDefaults.removeObject(forKey: "explicitStyle")
        #expect(model.explicitStyle == .style2, "explicitStyle should revert to default (.style2) when removed from UserDefaults")
    }

    @MainActor
    @Test("MainActor Support")
    func mainActorSupport() async {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModelMainActor(userDefaults: userDefaults)

        // Test initial values
        #expect(model.name == "Test", "name should start as Test")
        #expect(model.count == 0, "count should start as 0")
        #expect(model.customKey == "CustomValue", "customKey should start as CustomValue")

        // Test setting values (should work without key path compilation errors)
        tracking(model, \.name, .direct)
        model.name = "MainActorTest"
        #expect(model.name == "MainActorTest", "name should be set to MainActorTest")

        tracking(model, \.count, .direct)
        model.count = 42
        #expect(model.count == 42, "count should be set to 42")

        tracking(model, \.customKey, .direct)
        model.customKey = "UpdatedValue"
        #expect(model.customKey == "UpdatedValue", "customKey should be set to UpdatedValue")

        // Backed properties do not support willSet/didSet
        #expect(model.setResult.isEmpty, "willSet/didSet should not run for backed properties")

        // Test that values persist to UserDefaults
        #expect(
            userDefaults.string(forKey: "name") == "MainActorTest",
            "name should be stored in UserDefaults")
        #expect(
            userDefaults.integer(forKey: "count") == 42,
            "count should be stored in UserDefaults")

        // Test custom key
        #expect(
            userDefaults.string(forKey: "main-actor-custom-key") == "UpdatedValue",
            "customKey should be stored with custom key")

        // Test external changes
        tracking(model, \.name, .userDefaults)
        userDefaults.set("ExternalMainActorName", forKey: "name")

        // Give some time for the async dispatch to complete
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        #expect(model.name == "ExternalMainActorName", "name should be updated from external change")
    }
}
