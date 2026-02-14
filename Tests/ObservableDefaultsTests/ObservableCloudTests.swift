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

    @Test("WillSet and DidSet are not supported for Backed Property in Development Mode")
    func willSetAndDidSetAreNotSupportedForBackedPropertyInDevelopmentMode() {
        let model = MockModelCloud(developmentMode: true)
        model.name = "test1"
        #expect(model.setResult.isEmpty, "willSet/didSet should not run for backed properties")
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

        @Test("Observe First ObservableOnly supports WillSet and DidSet", .testMode)
        func observeFirstObservableOnlySupportsWillSetAndDidSet() {
            let model = MockModelCloudObserveFirstWithObservers(developmentMode: false)
            model.observableOnly = "Test2"
            #expect(
                model.setResult == ["willSet: Test2", "didSet: ObservableOnly"],
                "willSet/didSet should run for observeFirst observable-only properties")
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

        @Test("WillSet and DidSet are not supported for Backed Property", .testMode)
        func willSetAndDidSetAreNotSupportedForBackedProperty() {
            let model = MockModelCloud(developmentMode: false)
            model.name = "test1"
            #expect(model.setResult.isEmpty, "willSet/didSet should not run for backed properties")
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
    
    @Test("Optional Property Support in Development Mode")
    func optionalPropertySupportInDevelopmentMode() {
        let model = MockModelCloudOptional(developmentMode: true)
        
        // Test initial values
        #expect(model.name == nil, "name should start as nil")
        #expect(model.optionalName == nil, "optionalName should start as nil")
        #expect(model.optionalAge == 30, "optionalAge should start as 30")
        #expect(model.optionalWithoutInitializer == nil, "optionalWithoutInitializer should start as nil")
        #expect(model.optionalWithCustomKey == false, "optionalWithCustomKey should start as false")
        #expect(model.optionalInt64 == Int64(9223372036854775807), "optionalInt64 should start as max Int64")
        #expect(model.optionalFloat == Float(3.14), "optionalFloat should start as 3.14")
        #expect(model.optionalBool == true, "optionalBool should start as true")
        #expect(model.optionalData == "CloudTest".data(using: .utf8), "optionalData should start with CloudTest data")
        #expect(model.optionalDate == Date(timeIntervalSince1970: 1640995200), "optionalDate should start as 2022-01-01")
        
        // Test setting values
        tracking(model, \.optionalName, .direct)
        model.optionalName = "CloudTestName"
        #expect(model.optionalName == "CloudTestName", "optionalName should be set to CloudTestName")
        
        tracking(model, \.optionalAge, .direct)
        model.optionalAge = nil
        #expect(model.optionalAge == nil, "optionalAge should be set to nil in development mode")
        
        // Test setting back to default value
        model.optionalAge = 30
        #expect(model.optionalAge == 30, "optionalAge should be set back to 30")
        
        tracking(model, \.optionalWithoutInitializer, .direct)
        model.optionalWithoutInitializer = 2.718
        #expect(model.optionalWithoutInitializer == 2.718, "optionalWithoutInitializer should be set to 2.718")
        
        // Test setting different types to nil (in development mode, they actually become nil)
        model.optionalInt64 = nil
        #expect(model.optionalInt64 == nil, "optionalInt64 should be nil in development mode")
        
        model.optionalFloat = nil
        #expect(model.optionalFloat == nil, "optionalFloat should be nil in development mode")
        
        model.optionalBool = nil
        #expect(model.optionalBool == nil, "optionalBool should be nil in development mode")
        
        model.optionalData = nil
        #expect(model.optionalData == nil, "optionalData should be nil in development mode")
        
        model.optionalDate = nil
        #expect(model.optionalDate == nil, "optionalDate should be nil in development mode")
        
        // Test setting new values
        model.optionalInt64 = 12345
        #expect(model.optionalInt64 == 12345, "optionalInt64 should be set to new value")
        
        model.optionalFloat = Float(2.718)
        #expect(model.optionalFloat == Float(2.718), "optionalFloat should be set to new value")
        
        model.optionalBool = false
        #expect(model.optionalBool == false, "optionalBool should be set to false")
        
        let newData = "NewCloudTest".data(using: .utf8)
        model.optionalData = newData
        #expect(model.optionalData == newData, "optionalData should be set to new value")
        
        let newDate = Date(timeIntervalSince1970: 1672531200) // 2023-01-01
        model.optionalDate = newDate
        #expect(model.optionalDate == newDate, "optionalDate should be set to new value")
    }
    
    #if !DEBUG
    @Test("Optional Property Support in Production Mode", .testMode)
    func optionalPropertySupportInProductionMode() {
        let model = MockModelCloudOptional(developmentMode: false)
        
        // Test initial values
        #expect(model.name == nil, "name should start as nil")
        #expect(model.optionalName == nil, "optionalName should start as nil")
        #expect(model.optionalAge == 30, "optionalAge should start as 30")
        #expect(model.optionalWithoutInitializer == nil, "optionalWithoutInitializer should start as nil")
        #expect(model.optionalWithCustomKey == false, "optionalWithCustomKey should start as false")
        
        // Test setting values that persist to mock store
        tracking(model, \.optionalName, .direct)
        model.optionalName = "ProductionCloudName"
        #expect(model.optionalName == "ProductionCloudName", "optionalName should be set in production mode")
        
        tracking(model, \.optionalAge, .direct)
        model.optionalAge = 25
        #expect(model.optionalAge == 25, "optionalAge should be set to 25 in production mode")
        
        // Test that values persist through mock NSUbiquitousKeyValueStore
        #expect(userDefaults.object(forKey: "optionalName") as? String == "ProductionCloudName", 
                "optionalName should be stored in mock store")
        #expect(userDefaults.object(forKey: "optionalAge") as? Int == 25, 
                "optionalAge should be stored in mock store")
        
        // Test custom key
        model.optionalWithCustomKey = true
        #expect(userDefaults.object(forKey: "cloud-custom-optional-key") as? Bool == true,
                "optionalWithCustomKey should be stored with custom key")
        
        // Test external changes simulation
        userDefaults.set("ExternalCloudName", forKey: "optionalName")
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            userInfo: [
                NSUbiquitousKeyValueStoreChangedKeysKey: ["optionalName"],
            ])
        #expect(model.optionalName == "ExternalCloudName", "optionalName should be updated from external change")
        
        // Test removing values (should revert to default)
        userDefaults.removeObject(forKey: "optionalName")
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            userInfo: [
                NSUbiquitousKeyValueStoreChangedKeysKey: ["optionalName"],
            ])
        #expect(model.optionalName == nil, "optionalName should revert to default (nil) when removed from cloud store")
        
        userDefaults.removeObject(forKey: "optionalAge")
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            userInfo: [
                NSUbiquitousKeyValueStoreChangedKeysKey: ["optionalAge"],
            ])
        #expect(model.optionalAge == 30, "optionalAge should revert to default (30) when removed from cloud store")
    }
    #endif
    
    @Test("Codable Type with Static Properties Support in Development Mode")
    func codableTypeWithStaticPropertiesSupportInDevelopmentMode() {
        let model = MockModelCloudCodable(developmentMode: true)
        
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
        
        // Test creating new instances to verify they work
        let newStyle = FontStyle(size: 50, weight: .bold, id: 4)
        model.style = newStyle
        #expect(model.style == newStyle, "style should be set to custom instance")
    }
    
    #if !DEBUG
    @Test("Codable Type with Static Properties Support in Production Mode", .testMode)
    func codableTypeWithStaticPropertiesSupportInProductionMode() {
        let model = MockModelCloudCodable(developmentMode: false)
        
        // Test initial values with static properties
        #expect(model.style == .style1, "style should start as .style1")
        #expect(model.explicitStyle == .style2, "explicitStyle should start as .style2")
        
        // Test setting values that persist to mock store
        tracking(model, \.style, .direct)
        model.style = .style3
        #expect(model.style == .style3, "style should be set to .style3 in production mode")
        
        // Test that Codable values persist through mock NSUbiquitousKeyValueStore
        let storedData = userDefaults.data(forKey: "style")
        #expect(storedData != nil, "style should be stored as Data in mock store")
        
        if let data = storedData {
            let decodedStyle = try? JSONDecoder().decode(FontStyle.self, from: data)
            #expect(decodedStyle == .style3, "stored style should decode to .style3")
        }
        
        // Test external changes simulation with Codable types
        let style1Data = try! JSONEncoder().encode(FontStyle.style1)
        userDefaults.set(style1Data, forKey: "style")
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            userInfo: [
                NSUbiquitousKeyValueStoreChangedKeysKey: ["style"],
            ])
        #expect(model.style == .style1, "style should be updated from external change")
        
        // Test removing values (should revert to default)
        userDefaults.removeObject(forKey: "style")
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            userInfo: [
                NSUbiquitousKeyValueStoreChangedKeysKey: ["style"],
            ])
        #expect(model.style == .style1, "style should revert to default (.style1) when removed from cloud store")
    }
    #endif
    
    @MainActor
    @Test("MainActor Support in Development Mode")
    func mainActorSupportInDevelopmentMode() async {
        let model = MockModelCloudMainActor(developmentMode: true)
        
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
    }
    
    #if !DEBUG
    @MainActor
    @Test("MainActor Support in Production Mode", .testMode)
    func mainActorSupportInProductionMode() async {
        let model = MockModelCloudMainActor(developmentMode: false)
        
        // Test initial values
        #expect(model.name == "Test", "name should start as Test")
        #expect(model.count == 0, "count should start as 0")
        #expect(model.customKey == "CustomValue", "customKey should start as CustomValue")
        
        // Test setting values that persist to mock store
        tracking(model, \.name, .direct)
        model.name = "MainActorProductionTest"
        #expect(model.name == "MainActorProductionTest", "name should be set in production mode")
        
        tracking(model, \.count, .direct)
        model.count = 100
        #expect(model.count == 100, "count should be set to 100 in production mode")
        
        // Test that values persist through mock NSUbiquitousKeyValueStore
        #expect(userDefaults.string(forKey: "name") == "MainActorProductionTest", 
                "name should be stored in mock store")
        #expect(userDefaults.integer(forKey: "count") == 100, 
                "count should be stored in mock store")
        
        // Test custom key
        model.customKey = "MainActorCustom"
        #expect(userDefaults.string(forKey: "main-actor-custom-key") == "MainActorCustom",
                "customKey should be stored with custom key")
        
        // Test external changes simulation
        userDefaults.set("ExternalMainActorName", forKey: "name")
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            userInfo: [
                NSUbiquitousKeyValueStoreChangedKeysKey: ["name"],
            ])
        
        // Give some time for the async Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        #expect(model.name == "ExternalMainActorName", "name should be updated from external change")
    }
    #endif
#endif
