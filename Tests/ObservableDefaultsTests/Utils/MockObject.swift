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
    var name: String?
    var optionalName: String? {
        willSet {
            setResult.append("willSet: \(String(describing: newValue))")
        }
        didSet {
            setResult.append("didSet: \(String(describing: oldValue))")
        }
    }

    var optionalAge: Int? = 25

    var optionalWithoutInitializer: Double?

    @DefaultsKey(userDefaultsKey: "custom-optional-key")
    var optionalWithCustomKey: Bool? = true

    @Ignore
    var setResult: [String] = []
}
