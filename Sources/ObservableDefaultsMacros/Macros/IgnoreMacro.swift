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

/// A macro that marks a property as neither observable nor stored in UserDefaults.
///
/// By default, properties in a class marked with `@ObservableDefaults` are automatically
/// made observable and synchronized with UserDefaults. The `@Ignore` macro excludes
/// properties from both behaviors, treating them as regular properties.
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Observable and stored in UserDefaults
///
///     @Ignore
///     var weight: Int = 70  // Neither observable nor stored in UserDefaults
/// }
/// ```
///
/// In Observe First mode:
/// ```swift
/// @ObservableDefaults(observeFirst: true)
/// class Settings {
///     var name: String = "Fatbobman"  // Only observable (not stored)
///
///     @DefaultsBacked
///     var age: Int = 25  // Observable and stored in UserDefaults
///
///     @Ignore
///     var weight: Int = 70  // Neither observable nor stored
/// }
/// ```
///
/// - Note: This macro works in both standard and Observe First modes
/// - Important: Properties marked with `@Ignore` will not trigger SwiftUI view updates
///   and will not be persisted to UserDefaults
public struct IgnoreMacro: PeerMacro {
    /// The name of the macro as used in source code
    static let name: String = "Ignore"

    /// Provides peer declarations for the `@Ignore` macro.
    ///
    /// This macro is a marker macro that doesn't generate additional code.
    /// Instead, it provides metadata that is read by the `@ObservableDefaults` macro
    /// to determine which properties should be excluded from observation and UserDefaults
    /// synchronization.
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
        in _: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        // This is a marker macro that provides metadata for other macros
        // Properties marked with @Ignore are excluded from observation and UserDefaults
        // synchronization
        []
    }
}
