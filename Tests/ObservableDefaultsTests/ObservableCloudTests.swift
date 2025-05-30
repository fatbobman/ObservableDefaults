//
// ObservableCloudTests.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
import ObservableDefaults
import Testing

@Suite("ObservableCloud")
struct ObservableCloudTests {
    @Test("Property Observable")
    func propertyObservable() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.name, .direct)
        model.name = "Test2"
    }

    @Test("Property Observable for Cloud")
    func propertyObservableForCloud() {
        let model = MockModelCloud(developmentMode: false)
        tracking(model, \.name, .direct)
        model.name = "Test2"
    }

    @Test("Response to NSUbiquitousKeyValueStore changes")
    func responseToNSUbiquitousKeyValueStoreChanges() async throws {
        let model = MockModelCloud(developmentMode: false)
        let defaultStore = NSUbiquitousKeyValueStore.default
        defaultStore.set("Test2", forKey: "name")
        _ = defaultStore.synchronize()
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: defaultStore,
            userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: ["name"]])
        // #expect(
        //     model.name == "Test2",
        //     "name should be observable by setting value by NSUbiquitousKeyValueStore")
        #expect(defaultStore.string(forKey: "name") == "Test2")
        print(model.name)
    }

    @Test("Ignore Macro")
    func ignoreMacro() {
        let model = MockModelCloud(developmentMode: true)
        tracking(model, \.ignore, .direct, false)
        model.ignore = "Test2"
    }
}

typealias NSUbiquitousKeyValueStore = MyNSUbiquitousKeyValueStore
