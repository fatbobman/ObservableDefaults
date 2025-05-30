//
// NSUbiquitousKeyValueStore.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

/// A mock class for NSUbiquitousKeyValueStore using UserDefaults
class MyNSUbiquitousKeyValueStore: @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let suiteName = "com.fatbobman.ObservableDefaults.CloudMock"

    static let `default` = MyNSUbiquitousKeyValueStore(suiteName: #function)

    /// Initialize a new instance of MyNSUbiquitousKeyValueStore
    init(suiteName: String) {
        // 使用自定义的 suite name 来隔离测试数据
        userDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }

    // MARK: - Set Methods

    func set(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: String?, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: Data?, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: [Any]?, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func set(_ value: [String: Any]?, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    // MARK: - Get Methods

    func object(forKey key: String) -> Any? {
        userDefaults.object(forKey: key)
    }

    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    func array(forKey key: String) -> [Any]? {
        userDefaults.array(forKey: key)
    }

    func dictionary(forKey key: String) -> [String: Any]? {
        userDefaults.dictionary(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: key)
    }

    func stringArray(forKey key: String) -> [String]? {
        userDefaults.stringArray(forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        userDefaults.integer(forKey: key)
    }

    func double(forKey key: String) -> Double {
        userDefaults.double(forKey: key)
    }

    // MARK: - Remove Methods

    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }

    // MARK: - Utility Methods

    func synchronize() -> Bool {
        userDefaults.synchronize()
    }

    var dictionaryRepresentation: [String: Any] {
        userDefaults.dictionaryRepresentation()
    }

    // 清理测试数据的方法
    func clearAllData() {
        userDefaults.removePersistentDomain(forName: suiteName)
    }
}

extension NSUbiquitousKeyValueStore {
    static let didChangeExternallyNotification: Notification
        .Name = .init("NSUbiquitousKeyValueStoreDidChangeExternallyNotification")
}
