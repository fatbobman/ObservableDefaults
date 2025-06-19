//
//  ------------------------------------------------
//  Original project: ObservableDefaults
//  Created on 2024/10/7 by Fatbobman(东坡肘子)
//  X: @fatbobman
//  Mastodon: @fatbobman@mastodon.social
//  GitHub: @fatbobman
//  Blog: https://fatbobman.com
//  ------------------------------------------------
//  Copyright © 2024-present Fatbobman. All rights reserved.

import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that automatically synchronizes properties with UserDefaults storage.
///
/// This macro generates getter and setter accessors that:
/// - Automatically store property values in UserDefaults
/// - Support custom UserDefaults keys via `@DefaultsKey` macro
/// - Integrate with SwiftUI's Observation framework for precise view updates
/// - Handle both internal property changes and external UserDefaults modifications
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Automatically adds @DefaultsBacked
///
///     @DefaultsKey(userDefaultsKey: "firstName")
///     var firstName: String = "John"  // Uses custom key
/// }
/// ```
///
/// - Note: Properties marked with `@DefaultsBacked` must have default values. Optional types are
/// supported and can omit default values (defaulting to nil)
public enum DefaultsBackedMacro {
    /// The name of the macro as used in source code
    static let name: String = "DefaultsBacked"
    /// The parameter name for specifying custom UserDefaults keys
    static let key: String = "userDefaultsKey"
}

extension DefaultsBackedMacro: AccessorMacro {
    /// Generates getter and setter accessors for properties marked with `@DefaultsBacked`.
    ///
    /// The generated accessors provide:
    /// - **Getter**: Retrieves values from UserDefaults using `UserDefaultsWrapper.getValue`
    /// - **Setter**: Stores values to UserDefaults using `UserDefaultsWrapper.setValue`
    /// - **Observation Integration**: Calls `access(keyPath:)` for getter and
    /// `withMutation(keyPath:)` for setter
    /// - **External Change Handling**: Respects `ignoreExternalChanges` and
    /// `ignoredKeyPathsForExternalUpdates` settings
    /// - **Preview Support**: Automatically handles Xcode preview environment
    ///
    /// - Parameters:
    ///   - declaration: The property declaration to generate accessors for
    ///   - context: The macro expansion context for error reporting
    /// - Returns: An array containing the getter and setter accessor declarations
    /// - Throws: Diagnostic errors for invalid property configurations
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else { return [] }

        // Property name as default UserDefaults key if no custom key is provided
        var keyString: String = identifier.trimmedDescription

        // Validate that the property can be persisted to UserDefaults
        guard property.isPersistent else {
            let diagnostic = Diagnostic.variableRequired(
                property: property,
                macroType: .observableDefaults)
            context.diagnose(diagnostic)
            return []
        }

        // Check if the property is optional to handle initialization differently
        var isOptionalType = false
        if let typeAnnotation = binding.typeAnnotation {
            let typeSyntax = typeAnnotation.type
            let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            isOptionalType = typeSyntax.is(OptionalTypeSyntax.self) ||
                typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) ||
                typeName.contains("Optional")
        }

        // Ensure the property has a default value (required for UserDefaults integration)
        // Optional types can have no initializer (defaults to nil)
        if binding.initializer == nil && !isOptionalType {
            let diagnostic = Diagnostic.initializerRequired(
                property: property,
                macroType: .observableDefaults)
            context.diagnose(diagnostic)
            return []
        }

        // Check for custom UserDefaults key specified via @DefaultsBacked(userDefaultsKey:) or
        // @DefaultsKey(userDefaultsKey:)
        // @DefaultsBacked takes precedence if both are present
        if let extractedKey: String = property.attributes.extractValue(
            forAttribute: DefaultsBackedMacro.name,
            argument: DefaultsBackedMacro.key) ??
            property.attributes.extractValue(
                forAttribute: DefaultsKeyMacro.name,
                argument: DefaultsKeyMacro.key)
        {
            keyString = extractedKey
        }

        // swiftformat:disable all
        // Generate getter that retrieves value from UserDefaults
        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(identifier))
                let key = _prefix + "\(raw: keyString)"
                return UserDefaultsWrapper.getValue(key, \(raw: defaultValuePrefixed)\(raw: identifier), _userDefaults)
            }
            """
        // swiftformat:enable all

        // Generate setter that stores value to UserDefaults with proper observation handling
        let setAccessor: AccessorDeclSyntax =
            """
            set {
                let key = _prefix + "\(raw: keyString)"
                let currentValue = UserDefaultsWrapper.getValue(key, _\(identifier), _userDefaults)
                // Only set the value if it has changed, reduce the view re-evaluation
                guard shouldSetValue(newValue, currentValue) else {
                    return
                }
                if _isExternalNotificationDisabled ||
                _ignoredKeyPathsForExternalUpdates.contains(\\.\(identifier)) ||
                ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    withMutation(keyPath: \\.\(identifier)) {
                        UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                         _\(raw: identifier) = newValue
                    }
                } else {
                    UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                    _\(raw: identifier) = newValue
                }
            }
            """

        return [
            getAccessor,
            setAccessor,
        ]
    }
}

extension DefaultsBackedMacro: PeerMacro {
    /// Generates a private storage property for the default value of properties marked with
    /// `@DefaultsBacked`.
    ///
    /// This creates a private property prefixed with underscore (e.g., `_name` for property `name`)
    /// that stores the default value used by the UserDefaults integration.
    ///
    /// Example:
    /// ```swift
    /// // Original property:
    /// var name: String = "Fatbobman"
    ///
    /// // Generated storage property:
    /// private var _name: String = "Fatbobman"
    /// ```
    ///
    /// - Parameters:
    ///   - declaration: The property declaration to generate storage for
    ///   - context: The macro expansion context (unused in this implementation)
    /// - Returns: An array containing the private storage property declaration
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              property.isPersistent
        else {
            return []
        }

        // Check if the property is optional
        var isOptionalType = false
        if let typeAnnotation = binding.typeAnnotation {
            let typeSyntax = typeAnnotation.type
            let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            isOptionalType = typeSyntax.is(OptionalTypeSyntax.self) ||
                typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) ||
                typeName.contains("Optional")
        }

        // Generate private storage property with underscore prefix, for willSet and didSet
        let storage = DeclSyntax(property.privatePrefixed("_"))

        // swiftformat:disable all
        // Generate default value storage property with double underscore prefix
        let defaultStorage: DeclSyntax
        if let initializer = binding.initializer {
            // Has explicit initializer
            let initializerDescription = initializer.description
            // Check if initializer is just "= nil" without type annotation
            if isOptionalType && initializerDescription.trimmingCharacters(in: .whitespacesAndNewlines) == "= nil" {
                // Add type annotation for "= nil" cases
                defaultStorage =
                    """
                    // initial value storage, never change after initialization
                    private let \(raw:defaultValuePrefixed)\(raw: identifier): \(raw: binding.typeAnnotation?.type.description ?? "Optional<Any>") = nil
                    """
            } else {
                // Check if we need to add type annotation for type context
                if let typeAnnotation = binding.typeAnnotation {
                    // Has explicit type annotation, add it to ensure type context
                    defaultStorage =
                        """
                        // initial value storage, never change after initialization
                        private let \(raw:defaultValuePrefixed)\(raw: identifier): \(raw: typeAnnotation.type.description) \(raw: initializerDescription)
                        """
                } else {
                    // No type annotation, use initializer as-is (may fail for ambiguous cases)
                    defaultStorage =
                        """
                        // initial value storage, never change after initialization
                        private let \(raw:defaultValuePrefixed)\(raw: identifier) \(raw: initializerDescription)
                        """
                }
            }
        } else if isOptionalType {
            // Optional type without initializer defaults to nil
            defaultStorage =
                """
                // initial value storage, never change after initialization
                private let \(raw:defaultValuePrefixed)\(raw: identifier): \(raw: binding.typeAnnotation?.type.description ?? "Optional<Any>") = nil
                """
        } else {
            // This should not happen due to earlier validation, but provide a fallback
            defaultStorage =
                """
                // initial value storage, never change after initialization
                private let \(raw:defaultValuePrefixed)\(raw: identifier): Any? = nil
                """
        }
        // swiftformat:enable all

        return [storage, defaultStorage]
    }
}

/// The prefix for the default value storage property.
///
/// This prefix is used to distinguish the default value storage property from the regular storage
/// property.
let defaultValuePrefixed = "_default_value_of_"
