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
}
