// This portion of code is derived from UserDefaultsObservation
// Source: https://github.com/tgeisse/UserDefaultsObservation
// The original code is licensed under the MIT License.

/*
 Copyright (c) 2024 Taylor Geisse

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation

/// A generic wrapper for `UserDefaults` that provides type-safe methods for getting and setting
/// values.
/// This struct uses static methods to handle different value types including:
/// - RawRepresentable types (enums)
/// - Optional RawRepresentable types
/// - UserDefaultsPropertyListValue types (basic types like String, Int, etc.)
/// - Optional UserDefaultsPropertyListValue types
/// - Codable types (custom types that can be encoded/decoded)
public struct UserDefaultsWrapper<Value> {
    /// Private initializer to prevent instantiation since this struct only provides static methods
    private init() {}

    // MARK: - Get Values

    /// Gets a RawRepresentable value from the user defaults store.
    /// This method is used for enum types that conform to RawRepresentable.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or conversion fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The enum value from the user defaults store, or the default value if the key is
    /// not found or conversion fails
    /// - Note: Uses `nonisolated` to allow concurrent access from different actors
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value,
        _ store: UserDefaults) -> Value
    where Value: RawRepresentable, Value.RawValue: UserDefaultsPropertyListValue {
        // Attempt to get the raw value from UserDefaults
        guard let rawValue = store.object(forKey: key) as? Value.RawValue else {
            return defaultValue
        }
        // Try to create the enum from the raw value, fallback to default if it fails
        return Value(rawValue: rawValue) ?? defaultValue
    }

    /// Gets an optional RawRepresentable value from the user defaults store.
    /// This method handles optional enum types.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or conversion fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The optional enum value from the user defaults store, or the default value if the
    /// key is not found or conversion fails
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value?,
        _ store: UserDefaults) -> Value?
    where Value: RawRepresentable, Value.RawValue: UserDefaultsPropertyListValue {
        // Attempt to get the raw value from UserDefaults
        guard let rawValue = store.object(forKey: key) as? Value.RawValue else {
            return defaultValue
        }
        // Try to create the enum from the raw value, fallback to default if it fails
        return Value(rawValue: rawValue) ?? defaultValue
    }

    /// Gets a basic property list value from the user defaults store.
    /// This method is used for basic types like String, Int, Bool, etc.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or type casting fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The value from the user defaults store, or the default value if the key is not
    /// found or type casting fails
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value,
        _ store: UserDefaults) -> Value
    where Value: UserDefaultsPropertyListValue {
        // Directly cast the object to the expected type, fallback to default if casting fails
        store.object(forKey: key) as? Value ?? defaultValue
    }

    /// Gets an optional basic property list value from the user defaults store.
    /// This method handles optional basic types like String?, Int?, Bool?, etc.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or type casting fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The optional value from the user defaults store, or the default value if the key
    /// is not found or type casting fails
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value?,
        _ store: UserDefaults) -> Value?
    where Value: UserDefaultsPropertyListValue {
        // Check if the key exists first
        guard let object = store.object(forKey: key) else {
            return defaultValue
        }
        // Try to cast to the expected type, fallback to default if casting fails
        return object as? Value ?? defaultValue
    }

    /// Gets a basic property list value from the user defaults store.
    /// This method is used for custom types that can be encoded/decoded using JSON.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or decoding fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The decoded value from the user defaults store, or the default value if the key
    /// is not found or decoding fails
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value,
        _ store: UserDefaults) -> Value
    where Value: UserDefaultsPropertyListValue & Codable {
        // Check if the key exists first
        guard let object = store.object(forKey: key) else {
            return defaultValue
        }
        // Try to cast to the expected type, fallback to default if casting fails
        return object as? Value ?? defaultValue
    }

    /// Gets an optional basic property list value from the user defaults store.
    /// This method is used for optional custom types that can be encoded/decoded using JSON.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default optional value to return if the key is not found or decoding fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The decoded optional value from the user defaults store, or the default value if the key
    /// is not found or decoding fails
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value?,
        _ store: UserDefaults) -> Value?
    where Value: UserDefaultsPropertyListValue & Codable {
        // Check if the key exists first
        guard let object = store.object(forKey: key) else {
            return defaultValue
        }
        // Try to cast to the expected type, fallback to default if casting fails
        return object as? Value ?? defaultValue
    }

    /// Gets a Codable value from the user defaults store.
    /// This method is used for custom types that can be encoded/decoded using JSON.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default value to return if the key is not found or decoding fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The decoded value from the user defaults store, or the default value if the key
    /// is not found or decoding fails
    @_disfavoredOverload
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value,
        _ store: UserDefaults) -> Value
    where Value: Codable {
        // Get the data from UserDefaults
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

    /// Gets an optional Codable value from the user defaults store.
    /// This method is used for optional custom types that can be encoded/decoded using JSON.
    /// - Parameters:
    ///   - key: The key to get the value for
    ///   - defaultValue: The default optional value to return if the key is not found or decoding fails
    ///   - store: The user defaults store to get the value from
    /// - Returns: The decoded optional value from the user defaults store, or the default value if the key
    /// is not found or decoding fails
    @_disfavoredOverload
    public nonisolated static func getValue(
        _ key: String,
        _ defaultValue: Value?,
        _ store: UserDefaults) -> Value?
    where Value: Codable {
        // Get the data from UserDefaults
        guard let data = store.data(forKey: key) else {
            return defaultValue
        }

        do {
            // Attempt to decode the data using JSONDecoder
            return try JSONDecoder().decode(Value?.self, from: data)
        } catch {
            // Return default value if decoding fails
            return defaultValue
        }
    }

    // MARK: - Set Values

    /// Sets a RawRepresentable value in the user defaults store.
    /// This method stores the raw value of enum types.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new enum value to store
    ///   - store: The user defaults store to set the value in
    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: RawRepresentable, Value.RawValue: UserDefaultsPropertyListValue {
        // Store the raw value of the enum
        store.set(newValue.rawValue, forKey: key)
    }

    /// Sets an optional RawRepresentable value in the user defaults store.
    /// This method stores the raw value of optional enum types.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new optional enum value to store (nil will remove the key)
    ///   - store: The user defaults store to set the value in
    public nonisolated static func setValue(
        _ key: String,
        _ newValue: Value?,
        _ store: UserDefaults)
    where Value: RawRepresentable, Value.RawValue: UserDefaultsPropertyListValue {
        // Store the raw value of the optional enum (nil if the enum is nil)
        store.set(newValue?.rawValue, forKey: key)
    }

    /// Sets a basic property list value in the user defaults store.
    /// This method stores basic types like String, Int, Bool, etc.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new value to store
    ///   - store: The user defaults store to set the value in
    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: UserDefaultsPropertyListValue {
        // Directly store the value
        store.set(newValue, forKey: key)
    }

    /// Sets an optional basic property list value in the user defaults store.
    /// This method stores optional basic types like String?, Int?, Bool?, etc.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new optional value to store (nil will remove the key)
    ///   - store: The user defaults store to set the value in
    public nonisolated static func setValue(
        _ key: String,
        _ newValue: Value?,
        _ store: UserDefaults)
    where Value: UserDefaultsPropertyListValue {
        // Store the optional value (nil will remove the key)
        store.set(newValue, forKey: key)
    }

    /// Sets a basic property list value in the user defaults store.
    /// This method stores basic types like String, Int, Bool, etc.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new value to store
    ///   - store: The user defaults store to set the value in
    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: UserDefaultsPropertyListValue & Codable {
        // Directly store the value
        store.set(newValue, forKey: key)
    }

    /// Sets an optional basic property list value in the user defaults store.
    /// This method stores optional basic types like String?, Int?, Bool?, etc.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new optional value to store (nil will remove the key)
    ///   - store: The user defaults store to set the value in
    public nonisolated static func setValue(
        _ key: String,
        _ newValue: Value?,
        _ store: UserDefaults)
    where Value: UserDefaultsPropertyListValue & Codable {
        // Store the optional value (nil will remove the key)
        store.set(newValue, forKey: key)
    }

    /// Sets a Codable value in the user defaults store.
    /// This method encodes custom types to JSON data before storing.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new Codable value to store
    ///   - store: The user defaults store to set the value in
    /// - Note: If encoding fails, the method silently returns without storing anything
    @_disfavoredOverload
    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: Codable {
        // Encode the value to JSON data
        guard let data = try? JSONEncoder().encode(newValue) else { return }
        // Store the encoded data
        store.set(data, forKey: key)
    }

    /// Sets a optional Codable value in the user defaults store.
    /// This method encodes custom types to JSON data before storing.
    /// - Parameters:
    ///   - key: The key to set the value for
    ///   - newValue: The new optional Codable value to store (nil will remove the key)
    ///   - store: The user defaults store to set the value in
    /// - Note: If encoding fails, the method silently returns without storing anything
    @_disfavoredOverload
    public nonisolated static func setValue(_ key: String, _ newValue: Value?, _ store: UserDefaults)
    where Value: Codable {
        guard let value = newValue else {
            store.removeObject(forKey: key)
            return
        }
        // Encode the value to JSON data
        guard let data = try? JSONEncoder().encode(value) else { return }
        // Store the encoded data
        store.set(data, forKey: key)
    }
}
