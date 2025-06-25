//
//  ------------------------------------------------
//  Original project: ObservableDefaults
//  Created on 2024/10/8 by Fatbobman(东坡肘子)
//  X: @fatbobman
//  Mastodon: @fatbobman@mastodon.social
//  GitHub: @fatbobman
//  Blog: https://fatbobman.com
//  ------------------------------------------------
//  Copyright © 2024-present Fatbobman. All rights reserved.

import Foundation

/// A type-safe wrapper for optional Codable values that can be stored in UserDefaults.
///
/// `Nullable<T>` is designed to solve the issue where Swift's built-in `Optional<T>` type
/// doesn't work correctly with custom Codable types in ObservableDefaults. When you try to
/// use optional Codable types like `User?`, the compiler selects the wrong method overload,
/// causing runtime crashes with "Attempt to insert non-property list object" errors.
///
/// ## The Problem
///
/// ```swift
/// struct User: Codable, CodableUserDefaultsPropertyListValue {
///     var name: String
///     var age: Int
/// }
///
/// @ObservableDefaults
/// class Settings {
///     var user: User? = nil  // ❌ Crashes at runtime!
/// }
/// ```
///
/// ## The Solution
///
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var user: Nullable<User> = Nullable.none  // ✅ Works perfectly!
/// }
/// ```
///
/// ## Usage Examples
///
/// ### Basic Usage
/// ```swift
/// @ObservableDefaults
/// class AppSettings {
///     var currentUser: Nullable<User> = Nullable.none
///     var userPreferences: Nullable<UserPrefs> = Nullable.none
/// }
///
/// let settings = AppSettings()
///
/// // Setting a value
/// let user = User(name: "John", age: 30)
/// settings.currentUser = Nullable.from(value: user)
///
/// // Setting to nil
/// settings.currentUser = Nullable.none
///
/// // Getting the value
/// if let user = settings.currentUser.value {
///     print("Current user: \(user.name)")
/// } else {
///     print("No user logged in")
/// }
/// ```
///
/// ### Convenient Methods
/// ```swift
/// // Create from optional value
/// let optionalUser: User? = getUser()
/// settings.currentUser = Nullable.from(value: optionalUser)
///
/// // Check if has value
/// if settings.currentUser.hasValue {
///     print("User is logged in")
/// }
///
/// // Direct pattern matching
/// switch settings.currentUser {
/// case .none:
///     print("No user")
/// case .some(let user):
///     print("User: \(user.name)")
/// }
/// ```
///
/// ## Why This Works
///
/// Unlike Swift's built-in `Optional<T>`, `Nullable<T>` directly conforms to
/// `CodableUserDefaultsPropertyListValue`, ensuring the compiler always selects
/// the correct JSON encoding/decoding methods instead of attempting direct storage.
///
/// ## Performance Notes
///
/// - **Zero overhead**: `Nullable<T>` is an enum with no additional memory overhead
/// - **Lazy encoding**: Values are only JSON-encoded when actually stored
/// - **Type safety**: Full compile-time type checking maintained
///
/// - Important: Only use for custom Codable types. Basic types like `Int?`, `String?` work fine with regular optionals
/// - Note: This type is specifically designed for @ObservableDefaults integration
/// - Warning: Do not use this for non-Codable types
public enum Nullable<T: Codable & Equatable>: CodableUserDefaultsPropertyListValue {
    /// Represents the absence of a value (equivalent to `nil`)
    case none
    
    /// Represents the presence of a value
    case some(T)
    
    /// Returns the wrapped value as an optional type.
    ///
    /// - Returns: The wrapped value if `.some(value)`, otherwise `nil`
    public var value: T? {
        switch self {
        case .some(let value):
            return value
        case .none:
            return nil
        }
    }
    
    /// Creates a `Nullable<T>` from an optional value.
    ///
    /// This is the recommended way to create `Nullable` instances from optional values.
    ///
    /// - Parameter value: The optional value to wrap
    /// - Returns: `.some(value)` if value is not nil, otherwise `.none`
    ///
    /// Example:
    /// ```swift
    /// let optionalUser: User? = getUser()
    /// settings.user = Nullable.from(value: optionalUser)
    /// ```
    public static func from(value: T?) -> Nullable<T> {
        if let value = value {
            return .some(value)
        }
        return .none
    }
    
    /// Returns `true` if the value is `.some`, `false` if `.none`.
    public var hasValue: Bool {
        switch self {
        case .some:
            return true
        case .none:
            return false
        }
    }
    
    /// Maps the wrapped value using the provided transform function.
    ///
    /// - Parameter transform: A closure that transforms the wrapped value
    /// - Returns: A new `Nullable` with the transformed value, or `.none` if original was `.none`
    public func map<U: Codable & Equatable>(_ transform: (T) -> U) -> Nullable<U> {
        switch self {
        case .some(let value):
            return .some(transform(value))
        case .none:
            return .none
        }
    }
    
    /// Returns the wrapped value or a default value if `.none`.
    ///
    /// - Parameter defaultValue: The value to return if this instance is `.none`
    /// - Returns: The wrapped value or the default value
    public func valueOrDefault(_ defaultValue: T) -> T {
        switch self {
        case .some(let value):
            return value
        case .none:
            return defaultValue
        }
    }
}

// MARK: - Codable Conformance

extension Nullable: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let optionalValue = try container.decode(T?.self)
        self = Nullable.from(value: optionalValue)
    }
}

// MARK: - Equatable Conformance

extension Nullable: Equatable {
    public static func == (lhs: Nullable<T>, rhs: Nullable<T>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.some(let lhsValue), .some(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension Nullable: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "Nullable.none"
        case .some(let value):
            return "Nullable.some(\(value))"
        }
    }
}

// MARK: - ExpressibleByNilLiteral

extension Nullable: ExpressibleByNilLiteral {
    /// Allows `Nullable<T>` to be initialized with `nil` literal.
    ///
    /// Example:
    /// ```swift
    /// let nullable: Nullable<User> = nil  // Equivalent to Nullable.none
    /// ```
    public init(nilLiteral: ()) {
        self = .none
    }
}