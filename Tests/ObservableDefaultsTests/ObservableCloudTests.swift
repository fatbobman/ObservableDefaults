//
// ObservableCloudTests.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
@testable import ObservableDefaults
import Testing

@MainActor
@Suite("ObservableCloud", .serialized)
struct ObservableCloudTests {
    let userDefaults = UserDefaults.mock

    init() {
        UserDefaults.clearMock()
    }

    @Test("Property Observable")
    func propertyObservable() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.name, .direct)
        model.name = "Test2"
    }

    @Test("Ignore Macro")
    func ignoreMacro() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.ignore, .direct, false)
        model.ignore = "Test2"
    }

    @Test("Ignore Same Value")
    func ignoreSameValueForBackedProperty() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.name, .direct, false)
        model.name = "Test" // same value

        tracking(model, \.observableOnly, .direct, false)
        model.observableOnly = "ObservableOnly" // same value
    }

    @Test("WillSet and DidSet for Backed Property in Development Mode")
    func willSetAndDidSetForBackedPropertyInDevelopmentMode() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.setResult, .direct)
        model.name = "test1"
        #expect(
            model.setResult == ["willSet: test1", "didSet: Test"],
            "setResult should be observable by setting value directly")
    }

    @Test("WillSet and DidSet for Observable Only Property in Development Mode")
    func willSetAndDidSetForObservableOnlyPropertyInDevelopmentMode() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.setResult, .direct)
        model.observableOnly = "test1"
        #expect(
            model.setResult == ["willSet: test1", "didSet: ObservableOnly"],
            "setResult should be observable by setting value directly")
    }

    @Test("WillSet and DidSet for Ignore Property")
    func willSetAndDidSetForIgnoreProperty() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.setResult, .direct)
        model.ignore = "test1"
        #expect(model.setResult == ["willSet: test1", "didSet: Ignore"])
    }
}

#if swift(>=6.1)
    extension ObservableCloudTests {
        @Test("Response to NSUbiquitousKeyValueStore changes from Notification", .testMode)
        func responseToNSUbiquitousKeyValueStoreChanges() async throws {
            let model = MockModelCloud(developmentMode: false)
            userDefaults.set("Test2", forKey: "name")
            userDefaults.synchronize()
            NotificationCenter.default.post(
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: nil,
                userInfo: [
                    NSUbiquitousKeyValueStoreChangedKeysKey: ["name"],
                ])
            #expect(model.name == "Test2")
        }

        @Test("Prefix", .testMode)
        func prefix() {
            let model = MockModelCloud(prefix: "test_")
            model.name = "Test2"
            #expect(userDefaults.string(forKey: "test_name") == "Test2")
        }

        @Test("Observe First", .testMode)
        func observeFirst() {
            let model = MockModelCloudObserveFirst(developmentMode: false)
            model.observableOnly = "Test2"
            userDefaults.synchronize()
            #expect(userDefaults.string(forKey: "observableOnly") == nil)
        }

        @Test("Specify Key Name", .testMode)
        func specifyKeyName() {
            let model = MockModelCloudKeyName(developmentMode: false)
            model.renameByBackedKey = "Test2"
            userDefaults.synchronize()
            #expect(userDefaults.string(forKey: "rename-by-backed-key") == "Test2")

            model.renameByDefaultsKey = "Test3"
            userDefaults.synchronize()
            #expect(userDefaults.string(forKey: "rename-by-defaults-key") == "Test3")

            model.mixKey = "Test4"
            userDefaults.synchronize()
            #expect(userDefaults.string(forKey: "mix-key-backed-key") == "Test4")
        }

        @Test("WillSet and DidSet for Backed Property", .testMode)
        func willSetAndDidSetForBackedProperty() {
            let model = MockModelCloud(developmentMode: false)
            tracking(model, \.setResult, .direct)
            model.name = "test1"
            #expect(
                model.setResult == ["willSet: test1", "didSet: Test"],
                "setResult should be observable by setting value directly")
        }

        @Test(
            "Default value never change after initialization even remove from NSUbiquitousKeyValueStore",
            .testMode)
        func defaultValueNeverChange() {
            let model = MockModelCloud(developmentMode: false)
            model.name = "Test2"
            userDefaults.synchronize()
            userDefaults.removeObject(forKey: "name")
            userDefaults.synchronize()
            NotificationCenter.default.post(
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: nil,
                userInfo: [
                    NSUbiquitousKeyValueStoreChangedKeysKey: ["name"],
                ])
            #expect(model.name == "Test", "initial value never change after initialization")
        }
    }
#endif
