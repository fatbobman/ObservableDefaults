//
// CloudBackedMacro.swift
// Created by Xu Yang on 2025-05-23.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that provides automatic NSUbiquitousKeyValueStore (iCloud Key-Value Storage) integration
/// for properties in classes marked with `@ObservableCloud`.
///
/// The `@CloudBacked` macro generates getter and setter accessors that:
/// - Store and retrieve values from NSUbiquitousKeyValueStore for cloud synchronization
/// - Support development mode for testing without CloudKit container
/// - Integrate with SwiftUI's Observation framework for precise view updates
/// - Handle immediate synchronization when configured
///
/// ## Usage
///
/// Basic usage with automatic key generation:
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     @CloudBacked
///     var username: String = "Fatbobman"  // Uses "username" as the cloud key
/// }
/// ```
///
/// With custom NSUbiquitousKeyValueStore key:
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     @CloudBacked(keyValueStoreKey: "user_name")
///     var username: String = "Fatbobman"  // Uses "user_name" as the cloud key
/// }
/// ```
///
/// ## Requirements
///
/// - Property must have a default value (initializer)
/// - Property type must not be optional
/// - Property type must conform to appropriate protocols:
///   - `CloudPropertyListValue` for basic types (String, Int, Bool, etc.)
///   - `RawRepresentable` for enums with CloudPropertyListValue raw values
///   - `Codable` for custom Codable types
///
/// ## Generated Code
///
/// For a property `var username: String = "default"`, the macro generates:
/// ```swift
/// var username: String = "default" {
///     get {
///         access(keyPath: \.username)
///         if _developmentMode_ {
///             return _username
///         } else {
///             let key = _prefix + "username"
///             return NSUbiquitousKeyValueStoreWrapper.getValue(key, _username)
///         }
///     }
///     set {
///         if _developmentMode_ {
///             let currentValue = _username
///             guard shouldSetValue(newValue, currentValue) else { return }
///             withMutation(keyPath: \.username) {
///                 _username = newValue
///             }
///         } else {
///             let key = _prefix + "username"
///             let currentValue = NSUbiquitousKeyValueStoreWrapper.getValue(key, _username)
///             guard shouldSetValue(newValue, currentValue) else { return }
///             NSUbiquitousKeyValueStoreWrapper.setValue(key, newValue)
///             if _syncImmediately {
///                 _ = NSUbiquitousKeyValueStore.default.synchronize()
///             }
///             withMutation(keyPath: \.username) {
///                 _username = newValue
///             }
///         }
///     }
/// }
/// private var _username: String = "default"
/// ```
///
/// ## Development Mode
///
/// In development mode, the macro uses memory storage instead of NSUbiquitousKeyValueStore,
/// allowing for testing without CloudKit container setup.
///
/// ## Error Handling
///
/// The macro performs compile-time validation and generates diagnostics for:
/// - Properties without default values
/// - Optional property types (not supported)
/// - Properties that don't conform to required protocols
///
/// - Note: This macro works in conjunction with `@ObservableCloud` and requires the host class
///   to provide necessary infrastructure (observation registrar, prefix, sync settings, etc.)
/// - Important: Can only be used on properties within classes marked with `@ObservableCloud`
public enum CloudBackedMacro {
    /// The name of the macro as used in source code
    static let name: String = "CloudBacked"
    /// The parameter name for specifying custom NSUbiquitousKeyValueStore keys
    static let key: String = "keyValueStoreKey"
}

// MARK: - AccessorMacro Implementation

extension CloudBackedMacro: AccessorMacro {
    /// Generates getter and setter accessors for properties marked with `@CloudBacked`.
    ///
    /// This method performs the following operations:
    /// 1. Validates the property declaration and extracts necessary information
    /// 2. Checks that the property meets all requirements for cloud storage
    /// 3. Determines the NSUbiquitousKeyValueStore key (custom or property name)
    /// 4. Generates getter that retrieves values from cloud storage or memory (dev mode)
    /// 5. Generates setter that stores values to cloud storage with optional immediate sync
    ///
    /// ## Validation Steps
    ///
    /// - Ensures the declaration is a variable property
    /// - Verifies the property doesn't already have custom accessors
    /// - Checks that the property can be persisted (conforms to required protocols)
    /// - Validates that the property has a default value
    /// - Ensures the property is not optional
    ///
    /// ## Generated Accessors
    ///
    /// **Getter:**
    /// - Calls `access(keyPath:)` for SwiftUI observation tracking
    /// - In development mode: returns the private storage property
    /// - In production mode: retrieves value from NSUbiquitousKeyValueStore via wrapper
    ///
    /// **Setter:**
    /// - In development mode: uses `withMutation(keyPath:)` for observation and updates private
    /// storage
    /// - In production mode: stores value to NSUbiquitousKeyValueStore and optionally synchronizes
    /// immediately
    ///
    /// - Parameters:
    ///   - node: The `@CloudBacked` attribute syntax (unused in current implementation)
    ///   - declaration: The property declaration to generate accessors for
    ///   - context: The macro expansion context for diagnostics
    /// - Returns: An array containing the generated getter and setter accessors
    /// - Throws: No errors are thrown, but diagnostics may be reported to the context
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // Validate and extract property information
        guard let property = declaration.as(VariableDeclSyntax.self),
            let binding = property.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else { return [] }

        // Check if the containing class has @MainActor attribute
        var hasMainActor = false
        for context in context.lexicalContext {
            if let classContext = context.as(ClassDeclSyntax.self) {
                hasMainActor = classContext.attributes.contains(where: { attribute in
                    if case let .attribute(attr) = attribute,
                        let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self)
                    {
                        return identifierType.name.text == "MainActor"
                    }
                    return false
                })
                break
            }
        }

        // Property name as default NSUbiquitousKeyValueStore key if no custom key is provided
        var keyString: String = identifier.trimmedDescription

        // Validate that the property can be persisted to NSUbiquitousKeyValueStore
        guard property.isPersistent else {
            let diagnostic = Diagnostic.variableRequired(
                property: property,
                macroType: .observableDefaults)
            context.diagnose(diagnostic)
            return []
        }

        if property.hasWillOrDidSetObserver {
            context.diagnose(
                .observersNotSupported(
                    property: property,
                    attributeName: "@\(CloudBackedMacro.name)"))
        }

        // Check if the property is optional to handle initialization differently
        var isOptionalType = false
        if let typeAnnotation = binding.typeAnnotation {
            let typeSyntax = typeAnnotation.type
            let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            isOptionalType = typeSyntax.is(OptionalTypeSyntax.self) || typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) || typeName.contains("Optional")
        }

        // Ensure the property has a default value (required for NSUbiquitousKeyValueStore
        // integration). Optional types can have no initializer (defaults to nil)
        if binding.initializer == nil && !isOptionalType {
            let diagnostic = Diagnostic.initializerRequired(
                property: property,
                macroType: .observableDefaults)
            context.diagnose(diagnostic)
            return []
        }

        // Check for custom NSUbiquitousKeyValueStore key specified via
        // @CloudBacked(keyValueStoreKey:) or @CloudKey(keyValueStoreKey:)
        if let extractedKey: String = property.attributes.extractValue(
            forAttribute: CloudBackedMacro.name,
            argument: CloudBackedMacro.key)
            ?? property.attributes.extractValue(
                forAttribute: CloudKeyMacro.name,
                argument: CloudKeyMacro.key)
        {
            keyString = extractedKey
        }

        // Generate getter that retrieves value from NSUbiquitousKeyValueStore or memory storage
        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(raw: identifier))
                if _developmentMode_ {
                    return _\(raw: identifier)
                } else {
                    let key = _prefix + "\(raw: keyString)"
                    return NSUbiquitousKeyValueStoreWrapper.default.getValue(key, \(raw: defaultValuePrefixed)\(raw: identifier))
                }
            }
            """

        // Generate setter that stores value to NSUbiquitousKeyValueStore with proper observation
        // handling, with MainActor support
        let setAccessor: AccessorDeclSyntax
        if hasMainActor {
            setAccessor =
                """
                set {
                    if _developmentMode_ {
                        let currentValue = _\(raw: identifier)
                        guard shouldSetValue(newValue, currentValue) else { return }
                        MainActor.assumeIsolated {
                            withMutation(keyPath: \\.\(raw: identifier)) {
                                _\(raw: identifier) = newValue
                            }
                        }
                    } else {
                        let key = _prefix + "\(raw: keyString)"
                        let store = NSUbiquitousKeyValueStoreWrapper.default
                        let currentValue = store.getValue(key, _\(raw: identifier))
                        guard shouldSetValue(newValue, currentValue) else { return }
                        store.setValue(key, newValue)
                        if _syncImmediately {
                            _ = store.synchronize()
                        }
                        MainActor.assumeIsolated {
                            withMutation(keyPath: \\.\(raw: identifier)) {
                                _\(raw: identifier) = newValue
                            }
                        }
                    }
                }
                """
        } else {
            setAccessor =
                """
                set {
                    if _developmentMode_ {
                        let currentValue = _\(raw: identifier)
                        guard shouldSetValue(newValue, currentValue) else { return }
                        withMutation(keyPath: \\.\(raw: identifier)) {
                            _\(raw: identifier) = newValue
                        }
                    } else {
                        let key = _prefix + "\(raw: keyString)"
                        let store = NSUbiquitousKeyValueStoreWrapper.default
                        let currentValue = store.getValue(key, _\(raw: identifier))
                        guard shouldSetValue(newValue, currentValue) else { return }
                        store.setValue(key, newValue)
                        if _syncImmediately {
                            _ = store.synchronize()
                        }
                        withMutation(keyPath: \\.\(raw: identifier)) {
                            _\(raw: identifier) = newValue
                        }
                    }
                }
                """
        }

        return [
            getAccessor,
            setAccessor,
        ]
    }
}

// MARK: - PeerMacro Implementation

extension CloudBackedMacro: PeerMacro {
    /// Generates a private storage property for each `@CloudBacked` property.
    ///
    /// This method creates a private property with an underscore prefix that serves as:
    /// - Memory storage in development mode
    /// - Default value holder for NSUbiquitousKeyValueStore operations
    /// - Fallback storage when cloud storage is unavailable
    ///
    /// For a property `var username: String = "default"`, this generates:
    /// ```swift
    /// private var _username: String = "default"
    /// ```
    ///
    /// ## Purpose
    ///
    /// The private storage property is essential for:
    /// - **Development Mode**: Acts as the actual storage when cloud storage is disabled
    /// - **Default Values**: Provides the default value for NSUbiquitousKeyValueStore operations
    /// - **Type Safety**: Ensures type consistency between the public property and storage
    /// - **Performance**: Avoids repeated cloud storage access for default values
    ///
    /// - Parameters:
    ///   - node: The `@CloudBacked` attribute syntax (unused)
    ///   - declaration: The property declaration to generate a peer for
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array containing the generated private storage property declaration
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only generate storage for valid persistent properties
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
            isOptionalType = typeSyntax.is(OptionalTypeSyntax.self) || typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) || typeName.contains("Optional")
        }

        // Generate private storage property with underscore prefix.
        // Persistent properties do not support property observers.
        let storage = DeclSyntax(property.privatePrefixedWithoutAccessors("_"))

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

        return [storage, defaultStorage]
    }
}
