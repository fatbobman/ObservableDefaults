//
// CloudKeyMacro.swift
// Created by Xu Yang on 2025-05-23.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import SwiftSyntax
import SwiftSyntaxMacros

/// A marker macro that provides custom NSUbiquitousKeyValueStore key specification for properties
/// used with `@CloudBacked`.
///
/// The `@CloudKey` macro is a metadata-only macro that doesn't generate any code itself.
/// Instead, it serves as an alternative syntax for specifying custom cloud storage keys
/// that are read by the `@CloudBacked` macro during code generation.
///
/// ## Purpose
///
/// This macro provides a cleaner, more explicit way to specify custom NSUbiquitousKeyValueStore
/// keys compared to using the parameter syntax of `@CloudBacked(keyValueStoreKey:)`.
///
/// ## Usage
///
/// ### Basic Usage
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     @CloudKey(keyValueStoreKey: "user_name")
///     @CloudBacked
///     var username: String = "Fatbobman"
/// }
/// ```
///
/// ### Equivalent to CloudBacked Parameter Syntax
/// ```swift
/// // These two approaches are functionally identical:
///
/// // Using @CloudKey (recommended for readability)
/// @CloudKey(keyValueStoreKey: "user_name")
/// @CloudBacked
/// var username: String = "Fatbobman"
///
/// // Using @CloudBacked parameter
/// @CloudBacked(keyValueStoreKey: "user_name")
/// var username: String = "Fatbobman"
/// ```
///
/// ### Multiple Properties with Custom Keys
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     @CloudKey(keyValueStoreKey: "app_theme")
///     @CloudBacked
///     var theme: String = "light"
///
///     @CloudKey(keyValueStoreKey: "user_preferences")
///     @CloudBacked
///     var preferences: UserPreferences = UserPreferences()
///
///     // Property without custom key uses property name as key
///     @CloudBacked
///     var isFirstLaunch: Bool = true  // Uses "isFirstLaunch" as key
/// }
/// ```
///
/// ## Key Naming Conventions
///
/// When choosing custom keys, consider these best practices:
/// - Use descriptive, stable names that won't change over app versions
/// - Avoid special characters that might cause issues with key-value storage
/// - Use consistent naming patterns across your app (e.g., snake_case or camelCase)
/// - Consider prefixing keys to avoid conflicts with system or other frameworks
///
/// ## Integration with CloudBacked
///
/// The `@CloudBacked` macro reads the `keyValueStoreKey` parameter from `@CloudKey`
/// during its expansion phase. The precedence order for key resolution is:
/// 1. `@CloudBacked(keyValueStoreKey:)` parameter (highest priority)
/// 2. `@CloudKey(keyValueStoreKey:)` parameter
/// 3. Property name (default fallback)
///
/// ## Advantages
///
/// - **Separation of Concerns**: Keeps key specification separate from storage behavior
/// - **Readability**: Makes custom key usage more explicit and visible
/// - **Flexibility**: Allows for future extensions without changing `@CloudBacked` syntax
/// - **Consistency**: Provides a uniform way to specify keys across different storage macros
///
/// ## Limitations
///
/// - Must be used in conjunction with `@CloudBacked` - has no effect on its own
/// - Only supports string-based key specification
/// - Cannot be used with properties that don't support cloud storage
///
/// - Note: This is a marker macro that provides metadata only - no code generation occurs
/// - Important: The specified key must be a valid NSUbiquitousKeyValueStore key
/// - Warning: Changing the key after deployment will cause existing cloud data to become
/// inaccessible
public struct CloudKeyMacro: PeerMacro {
    /// The name of the macro as used in source code
    static let name: String = "CloudKey"
    /// The parameter name for specifying the custom NSUbiquitousKeyValueStore key
    static let key: String = "keyValueStoreKey"

    /// Provides peer declarations for the `@CloudKey` macro.
    ///
    /// This macro is a marker macro that doesn't generate additional code.
    /// Instead, it provides metadata that is read by the `@CloudBacked` macro
    /// to determine the custom NSUbiquitousKeyValueStore key for a property.
    ///
    /// ## Implementation Details
    ///
    /// The macro serves as a metadata container that:
    /// - Stores the custom key specification in the attribute syntax tree
    /// - Allows `@CloudBacked` to extract the key during its expansion phase
    /// - Provides no runtime behavior or code generation
    /// - Validates that the macro is properly formatted (handled by Swift compiler)
    ///
    /// ## Macro Expansion Process
    ///
    /// 1. Swift compiler parses the `@CloudKey(keyValueStoreKey: "custom_key")` attribute
    /// 2. This method is called but returns an empty array (no peer declarations)
    /// 3. When `@CloudBacked` expands, it searches for `@CloudKey` attributes
    /// 4. The custom key is extracted and used for NSUbiquitousKeyValueStore operations
    ///
    /// ## Error Handling
    ///
    /// Since this is a marker macro, most validation occurs in the `@CloudBacked` macro:
    /// - Invalid key formats are handled by NSUbiquitousKeyValueStore at runtime
    /// - Missing `@CloudBacked` companion results in the key being ignored (no error)
    /// - Malformed attribute syntax is caught by the Swift compiler during parsing
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node containing the keyValueStoreKey parameter (unused in
    /// expansion)
    ///   - declaration: The property declaration this macro is attached to (unused in expansion)
    ///   - context: The macro expansion context for potential diagnostics (unused in current
    /// implementation)
    /// - Returns: An empty array as this macro doesn't generate peer declarations
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // This is a marker macro that provides metadata for other macros
        // No peer declarations are generated - the macro serves only as a metadata container
        // for the @CloudBacked macro to read during its expansion phase
        []
    }
}
