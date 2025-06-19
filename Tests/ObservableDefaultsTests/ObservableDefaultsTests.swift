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
        model.name = "Test" // same value
    }

    @Test("Ignore Same Value Set for Observable Only Property")
    func ignoreSameValueForObservableOnlyProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        tracking(model, \.observableOnly, .direct, false)
        model.observableOnly = "ObservableOnly" // same value
    }

    @Test("WillSet and DidSet for Backed Property")
    func willSetAndDidSetForBackedProperty() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        tracking(model, \.setResult, .direct)
        model.name = "test1"
        #expect(
            model.setResult == ["willSet: test1", "didSet: Test"],
            "setResult should be observable by setting value directly")
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

        // Test initial values
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
}
