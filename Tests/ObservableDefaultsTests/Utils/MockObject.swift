//
// MockObject.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
import ObservableDefaults

@ObservableDefaults
class MockModel {
    var name: String = "Test" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    var age: Int = 18

    @Ignore
    var ignore: String = "Ignore" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    @ObservableOnly
    var observableOnly: String = "ObservableOnly" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    var hello: String {
        name.uppercased()
    }

    @Ignore
    var setResult: [String] = []
}

@ObservableDefaults(autoInit: false)
class MockModelAutoInitFalse {
    var name: String = "Test"

    init(name: String, defaults: UserDefaults) {
        _userDefaults = defaults
        self.name = name
        // observerStarter(observableKeysBlacklist: [])
    }
}

@ObservableDefaults(observeFirst: true)
class MockModelObserveFirst {
    var observableOnly: String = "ObservableOnly"

    @DefaultsBacked
    var name: String = "Test"
}

@ObservableDefaults(observeFirst: true)
class MockModelObserveFirstWithObservers {
    var observableOnly: String = "ObservableOnly" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    var observableCollection: [String] = ["ObservableOnly"] {
        willSet {
            setResult.append("willSet collection: \(newValue)")
        }
        didSet {
            setResult.append("didSet collection: \(oldValue)")
        }
    }

    @DefaultsBacked
    var name: String = "Test"

    @Ignore
    var setResult: [String] = []
}

@ObservableDefaults
class MockModelKeyName {
    @DefaultsBacked(userDefaultsKey: "rename-by-backed-key")
    var renameByBackedKey: String = "Test"

    @DefaultsKey(userDefaultsKey: "rename-by-defaults-key")
    var renameByDefaultsKey: String = "Test"

    /*
     if both are specified, the DefaultsBacked will be used
     if only one is specified, the DefaultsKey will be used
     if neither is specified, the property name will be used
     */
    @DefaultsKey(userDefaultsKey: "mix-key-defaults-key")
    @DefaultsBacked(userDefaultsKey: "mix-key-backed-key")
    var mixKey: String = "Test"
}

@ObservableCloud
class MockModelCloud {
    var name: String = "Test" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    @ObservableOnly
    var observableOnly: String = "ObservableOnly" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    @Ignore
    var ignore: String = "Ignore" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    @Ignore
    var setResult: [String] = []
}

@ObservableCloud(observeFirst: true)
class MockModelCloudObserveFirst {
    @CloudBacked
    var name: String = "Test"

    var observableOnly: String = "ObservableOnly"

    @Ignore
    var ignore: String = "Ignore"
}

@ObservableCloud(observeFirst: true)
class MockModelCloudObserveFirstWithObservers {
    @CloudBacked
    var name: String = "Test"

    var observableOnly: String = "ObservableOnly" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    @Ignore
    var setResult: [String] = []
}

@ObservableCloud
class MockModelCloudKeyName {
    @CloudBacked(keyValueStoreKey: "rename-by-backed-key")
    var renameByBackedKey: String = "Test"

    @CloudKey(keyValueStoreKey: "rename-by-defaults-key")
    var renameByDefaultsKey: String = "Test"

    /*
     if both are specified, the CloudBacked will be used
     if only one is specified, the CloudKey will be used
     if neither is specified, the property name will be used
     */
    @CloudKey(keyValueStoreKey: "mix-key-defaults-key")
    @CloudBacked(keyValueStoreKey: "mix-key-backed-key")
    var mixKey: String = "Test"
}

/// Test Codable types
struct FontStyle: Codable, Hashable, Identifiable {
    let size: CGFloat
    let weight: Weight
    let id: Int

    static let style1 = FontStyle(size: 20, weight: .bold, id: 1)
    static let style2 = FontStyle(size: 30, weight: .regular, id: 2)
    static let style3 = FontStyle(size: 40, weight: .heavy, id: 3)

    enum Weight: Int, Codable {
        case bold, regular, heavy
    }
}

/// Codable type with static properties test
@ObservableDefaults
class MockModelCodable {
    var style: FontStyle = .style1
    var explicitStyle: FontStyle = FontStyle.style2

    @Ignore
    var setResult: [String] = []
}

/// Codable type with static properties test for Cloud
@ObservableCloud
class MockModelCloudCodable {
    var style: FontStyle = .style1
    var explicitStyle: FontStyle = FontStyle.style2

    @Ignore
    var setResult: [String] = []
}

/// Optional support for Cloud
@ObservableCloud
class MockModelCloudOptional {
    var name: String?
    var optionalName: String? = nil {
        willSet {
            setResult.append("willSet: \(String(describing: newValue))")
        }
        didSet {
            setResult.append("didSet: \(String(describing: oldValue))")
        }
    }

    var optionalAge: Int? = 30

    var optionalWithoutInitializer: Double?

    @CloudKey(keyValueStoreKey: "cloud-custom-optional-key")
    var optionalWithCustomKey: Bool? = false

    // Test Int64 specific support
    var optionalInt64: Int64? = Int64(9223372036854775807)

    // Test different basic types
    var optionalFloat: Float? = Float(3.14)
    var optionalBool: Bool? = true
    var optionalData: Data? = "CloudTest".data(using: .utf8)
    var optionalDate: Date? = Date(timeIntervalSince1970: 1640995200)  // 2022-01-01

    @Ignore
    var setResult: [String] = []
}

/// No default value
@ObservableDefaults(autoInit: false)
class MockModelNoDefaultValue {
    @ObservableOnly
    var noDefaultValue: String = "Test"

    init(noDefaultValue: String) {
        self.noDefaultValue = noDefaultValue
    }
}

/// Optional support
@ObservableDefaults
class MockModelOptional {
    var name: String? = nil
    var optionalName: String? = nil {
        willSet {
            setResult.append("willSet: \(String(describing: newValue))")
        }
        didSet {
            setResult.append("didSet: \(String(describing: oldValue))")
        }
    }

    var optionalAge: Int? = 25

    var optionalWithoutInitializer: Double? = nil

    @DefaultsKey(userDefaultsKey: "custom-optional-key")
    var optionalWithCustomKey: Bool? = true

    @Ignore
    var setResult: [String] = []
}

/// MainActor support for Cloud
@MainActor
@ObservableCloud
class MockModelCloudMainActor {
    var name: String = "Test" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    var count: Int = 0

    @CloudKey(keyValueStoreKey: "main-actor-custom-key")
    var customKey: String = "CustomValue"

    @Ignore
    var setResult: [String] = []
}

/// MainActor support for UserDefaults
@MainActor
@ObservableDefaults
class MockModelMainActor {
    var name: String = "Test" {
        willSet {
            setResult.append("willSet: \(newValue)")
        }
        didSet {
            setResult.append("didSet: \(oldValue)")
        }
    }

    var count: Int = 0

    @DefaultsKey(userDefaultsKey: "main-actor-custom-key")
    var customKey: String = "CustomValue"

    @Ignore
    var setResult: [String] = []
}
