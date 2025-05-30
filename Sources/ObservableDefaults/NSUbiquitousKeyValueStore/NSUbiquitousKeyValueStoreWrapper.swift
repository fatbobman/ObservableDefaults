//
// NSUbiquitousKeyValueStoreWrapper.swift
// Created by Xu Yang on 2025-05-23.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

/// A wrapper for `NSUbiquitousKeyValueStore` that provides type-safe methods for getting
/// and setting values.
/// This struct provides methods to handle different value types including:
/// - RawRepresentable types (enums)
/// - Optional RawRepresentable types
/// - CloudPropertyListValue types (basic types like String, Int, etc.)
/// - Optional CloudPropertyListValue types
/// - CodableCloudPropertyListValue types (custom types that can be encoded/decoded)
public struct NSUbiquitousKeyValueStoreWrapper: Sendable {
    /// The default instance of NSUbiquitousKeyValueStoreWrapper.
    public static let `default` = NSUbiquitousKeyValueStoreWrapper()

    /// Private initializer to prevent instantiation since this struct only provides static methods
    private init() {}

    #if DEBUG
        /// A TaskLocal variable to determine if the current environment is a test environment.
        @TaskLocal
        static var isTestEnvironment: Bool = false
    #endif

    /// A private property to store the cloud store.
    private var store: ObservableDefaultsCloudStoreProtocol {
        #if DEBUG
            return Self.isTestEnvironment ? MockUbiquitousKeyValueStore
                .default : NSUbiquitousKeyValueStore.default
        #else
            return NSUbiquitousKeyValueStore.default
        #endif
    }

    // MARK: - Get Values

    /// Gets a RawRepresentable value from the ubiquitous key-value store.
    /// This method is used for enum types that conform to RawRepresentable.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or conversion fails
    /// - Returns: The enum value from the store, or the default value if the key is not found or
    /// conversion fails
    public func getValue<Value>(
        _ key: String,
        _ defaultValue: Value) -> Value
        where Value: RawRepresentable, Value.RawValue: CloudPropertyListValue
    {
        // Attempt to get the raw value from NSUbiquitousKeyValueStore
        guard let rawValue = store.object(forKey: key) as? Value.RawValue
        else {
            return defaultValue
        }
        // Try to create the enum from the raw value, fallback to default if it fails
        return Value(rawValue: rawValue) ?? defaultValue
    }

    /// Gets an optional RawRepresentable value from the ubiquitous key-value store.
    /// This method handles optional enum types.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or conversion fails
    /// - Returns: The optional enum value from the store, or the default value if the key is not
    /// found or conversion fails
    public func getValue<R>(
        _ key: String,
        _ defaultValue: R?) -> R?
    where R: RawRepresentable, R.RawValue: CloudPropertyListValue {
        // Attempt to get the raw value from NSUbiquitousKeyValueStore
        guard let rawValue = store.object(forKey: key) as? R.RawValue
        else {
            return defaultValue
        }
        // Try to create the enum from the raw value, fallback to default if it fails
        return R(rawValue: rawValue) ?? defaultValue
    }

    /// Gets a basic property list value from the ubiquitous key-value store.
    /// This method is used for basic types like String, Int, Bool, etc.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or type casting fails
    /// - Returns: The value from the store, or the default value if the key is not found or type
    /// casting fails
    public func getValue<Value>(
        _ key: String,
        _ defaultValue: Value) -> Value
    where Value: CloudPropertyListValue {
        // Directly cast the object to the expected type, fallback to default if casting fails
        store.object(forKey: key) as? Value ?? defaultValue
    }

    /// Gets an optional basic property list value from the ubiquitous key-value store.
    /// This method handles optional basic types like String?, Int?, Bool?, etc.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or type casting fails
    /// - Returns: The optional value from the store, or the default value if the key is not found
    /// or type casting fails
    public func getValue<R>(
        _ key: String,
        _ defaultValue: R?) -> R?
    where R: CloudPropertyListValue {
        store.object(forKey: key) as? R ?? defaultValue
    }

    /// Gets a Codable value from the ubiquitous key-value store.
    /// This method is used for custom types that can be encoded/decoded using JSON.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or decoding fails
    /// - Returns: The decoded value from the store, or the default value if the key is not found or
    /// decoding fails
    public func getValue<Value>(
        _ key: String,
        _ defaultValue: Value) -> Value
    where Value: CodableCloudPropertyListValue {
        // Get the data from NSUbiquitousKeyValueStore
        guard let data = store.data(forKey: key) else {
            return defaultValue
        }

        do {
            // Attempt to decode the data using JSONDecoder
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            // Return default value if decoding fails
            return defaultValue
        }
    }

    /// Gets a Int64 value from the ubiquitous key-value store.
    /// This method is specifically for non-optional Int64 values.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The Int64 value from the store, or the default value if the key is not found
    /// - Note: This method uses longLong(forKey:) to avoid the issue where
    ///   NSUbiquitousKeyValueStore returns 0 for non-existent keys
    /// - Important: This method is only for non-optional Int64. Optional Int64? values
    ///   should use the generic optional handling method
    public func getValue(
        _ key: String,
        _ defaultValue: Int64) -> Int64
    {
        // Get the value from NSUbiquitousKeyValueStore
        let value = store.longLong(forKey: key)
        // Check if the value is 0 and the key exists in the store
        // This is a workaround for the issue where NSUbiquitousKeyValueStore returns 0
        return store.object(forKey: key) != nil ? value : defaultValue
    }

    // MARK: - Set Values

    /// Sets a RawRepresentable value in the ubiquitous key-value store.
    /// This method stores the raw value of enum types.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new enum value to store
    public func setValue<Value>(
        _ key: String,
        _ newValue: Value)
    where Value: RawRepresentable, Value.RawValue: CloudPropertyListValue {
        // Store the raw value of the enum
        store.set(newValue.rawValue, forKey: key)
    }

    /// Sets an optional RawRepresentable value in the ubiquitous key-value store.
    /// This method stores the raw value of optional enum types.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new optional enum value to store (nil will remove the key)
    public func setValue<R>(
        _ key: String,
        _ newValue: R?)
    where R: RawRepresentable, R.RawValue: CloudPropertyListValue {
        // Store the raw value of the optional enum (nil if the enum is nil)
        if let newValue {
            store.set(newValue.rawValue, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
    }

    /// Sets a basic property list value in the ubiquitous key-value store.
    /// This method stores basic types like String, Int, Bool, etc.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new value to store
    public func setValue(
        _ key: String,
        _ newValue: some CloudPropertyListValue)
    {
        // Directly store the value
        store.set(newValue, forKey: key)
    }

    /// Sets an optional basic property list value in the ubiquitous key-value store.
    /// This method stores optional basic types like String?, Int?, Bool?, etc.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new optional value to store (nil will remove the key)
    public func setValue(
        _ key: String,
        _ newValue: (some CloudPropertyListValue)?)
    {
        // Store the optional value (nil will remove the key)
        if let newValue {
            store.set(newValue, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
    }

    /// Sets a Codable value in the ubiquitous key-value store.
    /// This method encodes custom types to JSON data before storing.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new Codable value to store
    /// - Note: If encoding fails, the method silently returns without storing anything
    public func setValue(
        _ key: String,
        _ newValue: some CodableCloudPropertyListValue)
    {
        // Encode the value to JSON data
        guard let data = try? JSONEncoder().encode(newValue) else { return }
        // Store the encoded data
        store.set(data, forKey: key)
    }

    /// Synchronizes the ubiquitous key-value store.
    /// - Returns: True if the synchronization was successful, false otherwise
    @discardableResult
    public func synchronize() -> Bool {
        store.synchronize()
    }
}
