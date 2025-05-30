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
///   - `CodableCloudPropertyListValue` for custom Codable types
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
        in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax]
    {
        // Validate and extract property information
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              // Ensure property doesn't already have custom accessors
              binding.accessorBlock == nil
        else { return [] }

        // Use property name as default NSUbiquitousKeyValueStore key
        var keyString: String = identifier.trimmedDescription

        // Validate that the property can be persisted to NSUbiquitousKeyValueStore
        guard property.isPersistent else {
            let diagnostic = Diagnostic.variableRequired(
                property: property,
                macroType: .observableDefaults)
            context.diagnose(diagnostic)
            return []
        }

        // Ensure the property has a default value (required for NSUbiquitousKeyValueStore
        // integration)
        if binding.initializer == nil {
            let diagnostic = Diagnostic.initializerRequired(
                property: property,
                macroType: .observableDefaults)
            context.diagnose(diagnostic)
            return []
        }

        // Validate that the property is not optional (optional types are not supported)
        if let typeAnnotation = binding.typeAnnotation {
            let typeSyntax = typeAnnotation.type
            let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if typeSyntax.is(OptionalTypeSyntax.self) ||
                typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) ||
                typeName.contains("Optional")
            {
                let diagnostic = Diagnostic.optionalTypeNotSupported(
                    property: property,
                    typeName: typeName,
                    macroType: .observableDefaults)
                context.diagnose(diagnostic)
                return []
            }
        }

        // Check for custom NSUbiquitousKeyValueStore key specified via
        // @CloudBacked(keyValueStoreKey:) or @CloudKey(keyValueStoreKey:)
        if let extractedKey: String = property.attributes.extractValue(
            forAttribute: CloudBackedMacro.name,
            argument: CloudBackedMacro.key) ??
            property.attributes.extractValue(
                forAttribute: CloudKeyMacro.name,
                argument: CloudKeyMacro.key)
        {
            keyString = extractedKey
        }

        let storageRestrictionsSyntax: AccessorDeclSyntax =
            """
            @storageRestrictions(initializes: _\(raw: identifier))
            init(initialValue) {
                _\(raw: identifier) = initialValue
            }
            """
        // swiftformat:disable all
        // Generate getter that retrieves value from NSUbiquitousKeyValueStore or memory storage
        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(raw: identifier))
                if _developmentMode_ {
                    return _\(raw: identifier)
                } else {
                    let key = _prefix + "\(raw: keyString)"
                    return NSUbiquitousKeyValueStoreWrapper.default.getValue(key, _\(raw: identifier))
                }
            }
            """
        // swiftformat:enable all

        // Generate setter that stores value to NSUbiquitousKeyValueStore with proper observation
        // handling
        let setAccessor: AccessorDeclSyntax =
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

        return [
            storageRestrictionsSyntax,
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
        in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        // Only generate storage for valid persistent properties
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isPersistent
        else {
            return []
        }

        // Generate private storage property with underscore prefix
        let storage = DeclSyntax(property.privatePrefixed("_"))
        return [storage]
    }
}
