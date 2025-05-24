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

public enum CloudBackedMacro {
    /// The name of the macro as used in source code
    static let name: String = "CloudBacked"
    /// The parameter name for specifying custom NSUbiquitousKeyValueStore keys
    static let key: String = "keyValueStoreKey"
}

extension CloudBackedMacro: AccessorMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              // Extract property name
              binding.accessorBlock == nil // Ensure property doesn't already have custom accessors
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
        // @CloudBacked(keyValueStoreKey:)
        // or @CloudKey(keyValueStoreKey:)
        if let extractedKey: String = property.attributes.extractValue(
            forAttribute: CloudBackedMacro.name,
            argument: CloudBackedMacro.key) ??
            property.attributes.extractValue(
                forAttribute: CloudKeyMacro.name,
                argument: CloudKeyMacro.key)
        {
            keyString = extractedKey
        }

        // Generate getter that retrieves value from UserDefaults
        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(identifier))
                switch _cloudKitRequirementMode {
                    case .development:
                        return _\(raw: identifier)
                    case .production:
                        let key = _prefix + "\(raw: keyString)"
                        return NSUbiquitousKeyValueStoreWrapper.getValue(key, _\(raw: identifier))
                }
            }
            """

        // Generate setter that stores value to UserDefaults with proper observation handling
        let setAccessor: AccessorDeclSyntax =
            """
            set {
                switch _cloudKitRequirementMode {
                    case .development:
                        withMutation(keyPath: \\.\(raw: identifier)) {
                            _\(identifier) = newValue
                        }
                    case .production:
                        let key = _prefix + "\(raw: keyString)"
                        NSUbiquitousKeyValueStoreWrapper.setValue(key, newValue)
                        if syncImmediately {
                            _cloudStore.synchronize()
                        }
                }
            }
            """

        return [
            getAccessor,
            setAccessor,
        ]
    }
}

extension CloudBackedMacro: PeerMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
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
