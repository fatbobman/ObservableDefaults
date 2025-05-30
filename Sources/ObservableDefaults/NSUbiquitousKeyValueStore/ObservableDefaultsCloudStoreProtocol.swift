//
// ObservableDefaultsCloudStoreProtocol.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

/// The protocol for the cloud store.
public protocol ObservableDefaultsCloudStoreProtocol {
    func object(forKey aKey: String) -> Any?

    func set(_ anObject: Any?, forKey aKey: String)

    func removeObject(forKey aKey: String)

    func string(forKey aKey: String) -> String?

    func array(forKey aKey: String) -> [Any]?

    func dictionary(forKey aKey: String) -> [String: Any]?

    func data(forKey aKey: String) -> Data?

    func longLong(forKey aKey: String) -> Int64

    func double(forKey aKey: String) -> Double

    func bool(forKey aKey: String) -> Bool

    func set(_ aString: String?, forKey aKey: String)

    func set(_ aData: Data?, forKey aKey: String)

    func set(_ anArray: [Any]?, forKey aKey: String)

    func set(_ aDictionary: [String: Any]?, forKey aKey: String)

    func set(_ value: Int64, forKey aKey: String)

    func set(_ value: Double, forKey aKey: String)

    func set(_ value: Bool, forKey aKey: String)

    var dictionaryRepresentation: [String: Any] { get }

    func synchronize() -> Bool
}

/// The default implementation of the cloud store.
extension NSUbiquitousKeyValueStore: ObservableDefaultsCloudStoreProtocol {}

