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

import SwiftSyntax
import SwiftSyntaxMacros

/// A macro that specifies a custom UserDefaults key for a property.
///
/// By default, ObservableDefaults uses the property name as the UserDefaults key.
/// The `@DefaultsKey` macro allows you to override this behavior and use a custom key name.
/// When a prefix is set at the class level, the final key becomes: prefix + custom_key
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     @DefaultsKey(userDefaultsKey: "firstName")
///     var name: String = "John"  // Stored with key "firstName" instead of "name"
///
///     var age: Int = 25  // Uses default key "age"
/// }
/// ```
///
/// With prefix:
/// ```swift
/// @ObservableDefaults(prefix: "myApp_")
/// class Settings {
///     @DefaultsKey(userDefaultsKey: "firstName")
///     var name: String = "John"  // Final key: "myApp_firstName"
/// }
/// ```
///
/// - Note: This macro works in conjunction with `@DefaultsBacked` and is automatically applied
///   when properties are marked with `@ObservableDefaults`
/// - Important: The prefix must not contain '.' characters
public struct DefaultsKeyMacro: PeerMacro {
    /// The name of the macro as used in source code
    static let name: String = "DefaultsKey"
    /// The parameter name for specifying the custom UserDefaults key
    static let key: String = "userDefaultsKey"

    /// Provides peer declarations for the `@DefaultsKey` macro.
    ///
    /// This macro is a marker macro that doesn't generate additional code.
    /// Instead, it provides metadata that is read by the `@DefaultsBacked` macro
    /// to determine the custom UserDefaults key for a property.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node (unused)
    ///   - declaration: The declaration this macro is attached to (unused)
    ///   - context: The macro expansion context (unused)
    /// - Returns: An empty array as this macro doesn't generate peer declarations
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // This is a marker macro that provides metadata for other macros
        // No peer declarations are generated
        []
    }
}
