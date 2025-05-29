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

/// A macro that marks a property as observable but not stored in UserDefaults.
///
/// This macro is used when you want a property to trigger SwiftUI view updates
/// but don't need it to be persisted to UserDefaults. It's particularly useful
/// in Observe First mode where this macro is automatically applied to properties
/// that don't have explicit `@DefaultsBacked` annotation.
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Stored in UserDefaults
///
///     @ObservableOnly
///     var height: Int = 190  // Observable but not stored in UserDefaults
/// }
/// ```
///
/// In Observe First mode:
/// ```swift
/// @ObservableDefaults(observeFirst: true)
/// class Settings {
///     var name: String = "fat"          // Automatically gets @ObservableOnly
///
///     @DefaultsBacked
///     var age: Int = 109               // Observable and stored in UserDefaults
/// }
/// ```
///
/// - Note: Properties marked with `@ObservableOnly` will trigger SwiftUI view updates
///   but their values will not persist between app launches
/// - Important: This macro is automatically applied in Observe First mode for properties
///   that don't explicitly use `@DefaultsBacked`
public enum ObservableOnlyMacro {
    /// The name of the macro as used in source code
    static let name: String = "ObservableOnly"
}

extension ObservableOnlyMacro: PeerMacro {
    /// Generates a private storage property for the observable property.
    ///
    /// This creates a private property prefixed with underscore (e.g., `_height` for property
    /// `height`)
    /// that stores the actual value. The original property becomes a computed property
    /// with getter and setter that integrate with the Observation framework.
    ///
    /// Example:
    /// ```swift
    /// // Original property:
    /// @ObservableOnly
    /// var height: Int = 190
    ///
    /// // Generated storage property:
    /// private var _height: Int = 190
    /// ```
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node (unused)
    ///   - declaration: The property declaration to generate storage for
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array containing the private storage property declaration
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isObservable
        else {
            return []
        }
        // Generate private storage property with underscore prefix
        let storage = DeclSyntax(property.privatePrefixed("_"))
        return [storage]
    }
}

extension ObservableOnlyMacro: AccessorMacro {
    /// Generates getter, setter, and modify accessors for observable properties.
    ///
    /// The generated accessors provide:
    /// - **Getter**: Calls `access(keyPath:)` for SwiftUI observation tracking and returns the
    /// private storage value
    /// - **Setter**: Uses `withMutation(keyPath:)` to notify observers and updates the private
    /// storage
    /// - **Modify Accessor**: Provides in-place mutation support with proper observation
    /// notifications
    ///
    /// Unlike `@DefaultsBacked`, these accessors only handle observation and do not
    /// interact with UserDefaults storage.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node (unused)
    ///   - declaration: The property declaration to generate accessors for
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array containing getter, setter, and modify accessor declarations
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isObservable,
              let identifier = property.identifier?.trimmed
        else {
            return []
        }

        // Skip generation if property is marked with @Ignore
        if property.hasMacroApplication(IgnoreMacro.name) {
            return []
        }

        let storageRestrictionsSyntax: AccessorDeclSyntax =
            """
            @storageRestrictions(initializes: _\(raw: identifier))
            init(initialValue) {
                _\(raw: identifier) = initialValue
            }
            """

        // Generate getter that integrates with SwiftUI observation
        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(identifier))
                return _\(identifier)
            }
            """

        // Generate setter that notifies observers of changes
        let setAccessor: AccessorDeclSyntax =
            """
            set {
                // Only set the value if it has changed, reduce the view re-evaluation
                guard shouldSetValue(newValue, _\(identifier)) else { return }
                withMutation(keyPath: \\.\(identifier)) {
                    _\(identifier) = newValue
                }
            }
            """

        // Generate modify accessor for in-place mutations
        let modifyAccessor: AccessorDeclSyntax =
            """
            _modify {
                access(keyPath: \\.\(identifier))
                _$observationRegistrar.willSet(self, keyPath: \\.\(identifier))
                defer { _$observationRegistrar.didSet(self, keyPath: \\.\(identifier)) }
                yield &_\(identifier)
            }
            """

        return [storageRestrictionsSyntax, getAccessor, setAccessor, modifyAccessor]
    }
}
