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
    var name: String = "Test"
    var age: Int = 18
    @Ignore
    var ignore: String = "Ignore"
    @ObservableOnly
    var observableOnly: String = "ObservableOnly"
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
