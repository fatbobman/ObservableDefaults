//
// MockUbiquitousKeyValueStore.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

#if DEBUG
    /// MockUbiquitousKeyValueStore is a mock implementation of the
    /// SendableObservableDefaultsCloudStoreProtocol.
    ///
    /// - It is used to test the ObservableDefaults library in a test environment.
    /// - It is not used in a production environment. It is only available in DEBUG mode.
    final class MockUbiquitousKeyValueStore: ObservableDefaultsCloudStoreProtocol,
        @unchecked Sendable
    {
        private let userDefaults: UserDefaults
        static let suiteName = "com.fatbobman.ObservableDefaults.MockUbiquitousKeyValueStore"

        static let `default` = MockUbiquitousKeyValueStore()

        init() {
            userDefaults = UserDefaults(suiteName: Self.suiteName)!
        }

        init(suiteName: String) {
            userDefaults = UserDefaults(suiteName: suiteName)!
        }

        // MARK: - Object methods

        func object(forKey aKey: String) -> Any? {
            userDefaults.object(forKey: aKey)
        }

        func set(_ anObject: Any?, forKey aKey: String) {
            userDefaults.set(anObject, forKey: aKey)
        }

        func removeObject(forKey aKey: String) {
            userDefaults.removeObject(forKey: aKey)
        }

        // MARK: - Typed getters

        func string(forKey aKey: String) -> String? {
            userDefaults.string(forKey: aKey)
        }

        func array(forKey aKey: String) -> [Any]? {
            userDefaults.array(forKey: aKey)
        }

        func dictionary(forKey aKey: String) -> [String: Any]? {
            userDefaults.dictionary(forKey: aKey)
        }

        func data(forKey aKey: String) -> Data? {
            userDefaults.data(forKey: aKey)
        }

        func longLong(forKey aKey: String) -> Int64 {
            Int64(userDefaults.integer(forKey: aKey))
        }

        func double(forKey aKey: String) -> Double {
            userDefaults.double(forKey: aKey)
        }

        func bool(forKey aKey: String) -> Bool {
            userDefaults.bool(forKey: aKey)
        }

        // MARK: - Typed setters

        func set(_ aString: String?, forKey aKey: String) {
            userDefaults.set(aString, forKey: aKey)
        }

        func set(_ aData: Data?, forKey aKey: String) {
            userDefaults.set(aData, forKey: aKey)
        }

        func set(_ anArray: [Any]?, forKey aKey: String) {
            userDefaults.set(anArray, forKey: aKey)
        }

        func set(_ aDictionary: [String: Any]?, forKey aKey: String) {
            userDefaults.set(aDictionary, forKey: aKey)
        }

        func set(_ value: Int64, forKey aKey: String) {
            userDefaults.set(value, forKey: aKey)
        }

        func set(_ value: Double, forKey aKey: String) {
            userDefaults.set(value, forKey: aKey)
        }

        func set(_ value: Bool, forKey aKey: String) {
            userDefaults.set(value, forKey: aKey)
        }

        // MARK: - Additional properties and methods

        var dictionaryRepresentation: [String: Any] {
            userDefaults.dictionaryRepresentation()
        }

        func synchronize() -> Bool {
            userDefaults.synchronize()
        }
    }
#endif
