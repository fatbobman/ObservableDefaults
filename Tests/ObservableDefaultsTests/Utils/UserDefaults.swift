//
// UserDefaults.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
@testable import ObservableDefaults
import Observation
import Testing

extension UserDefaults {
    /// Get a test instance of UserDefaults
    /// - Parameter suiteName: The suite name of the UserDefaults instance
    /// - Returns: A test instance of UserDefaults
    static func getTestInstance(suiteName: String) -> UserDefaults {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.removePersistentDomain(forName: suiteName)
        userDefaults?.synchronize()
        return userDefaults!
    }
}

extension UserDefaults {
    static var mock: UserDefaults {
        UserDefaults(suiteName: MockUbiquitousKeyValueStore.suiteName)!
    }

    static func clearMock() {
        mock.removePersistentDomain(forName: MockUbiquitousKeyValueStore.suiteName)
        mock.synchronize()
    }
}

