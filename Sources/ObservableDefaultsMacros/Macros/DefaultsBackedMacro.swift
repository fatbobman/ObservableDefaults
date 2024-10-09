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

// A macro generated by ObservableDefaults to add UserDefaults-related logic to properties
public enum DefaultsBackedMacro {
    static let name: String = "DefaultsBacked"
}

extension DefaultsBackedMacro: AccessorMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self), // variable name
              binding.accessorBlock == nil // should not have get set
        else { return [] }

        // The default key is the parameter name
        var keyString: String = identifier.trimmedDescription

        // Check if it can be persisted
        guard property.isPersistent else {
            let diagnostic = Diagnostic.variableRequired(property: property)
            context.diagnose(diagnostic)
            return []
        }

        // A default value must be provided, otherwise an error is reported
        if binding.initializer == nil {
            let diagnostic = Diagnostic.initializerRequired(property: property)
            context.diagnose(diagnostic)
            return []
        }

        // Extract the type annotation of the variable, which requires explicit type annotation
        guard let typeAnnotation = binding.typeAnnotation else {
            let diagnostic = Diagnostic.explicitTypeAnnotationRequired(property: property)
            context.diagnose(diagnostic)
            return []
        }

        // Check if the type is optional, if so, report an error (supporting ? ! and Optional three ways of judgment)
        let typeSyntax = typeAnnotation.type
        let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if typeSyntax.is(OptionalTypeSyntax.self) ||
            typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) ||
            typeName.contains("Optional")
        {
            let diagnostic = Diagnostic.optionalTypeNotSupported(property: property, typeName: typeName)
            context.diagnose(diagnostic)
            return []
        }

        // If @Attribute(originalKey:) is annotated, use the user-specified Key
        if let extractedKey: String = property.attributes.extractValue(forAttribute: DefaultsKeyMacro.name, argument: DefaultsKeyMacro.key) {
            keyString = extractedKey
        }

        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(identifier))
                let key = _prefix + "\(raw: keyString)"
                return UserDefaultsWrapper.getValue(key, _\(identifier), _userDefaults)
            }
            """

        let setAccessor: AccessorDeclSyntax =
            """
            set {
                let key = _prefix + "\(raw: keyString)"
                if _isExternalNotificationDisabled {
                    withMutation(keyPath: \\.\(identifier)) {
                        UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                    }
                } else {
                    UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
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
    public static func expansion<
        Context: MacroExpansionContext,
        Declaration: DeclSyntaxProtocol
    >(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in _: Context
    ) throws -> [DeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isPersistent,
              let identifier = property.identifier
        else {
            return []
        }

        guard let binding = property.bindings.first else {
            return []
        }

        let defaultValue: String = binding
            .initializer?
            .trimmedDescription
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces) ?? ""

        let store: DeclSyntax =
            """
            private var _\(raw: identifier.text) = \(raw: defaultValue)
            """
        return [store]
    }
}

// private func findEnclosingTypeName(of node: some SyntaxProtocol) -> String? {
//    var currentNode: SyntaxProtocol = node
//    while let parent = currentNode.parent {
//        if let structDecl = parent.as(StructDeclSyntax.self) {
//            return structDecl.name.text
//        } else if let classDecl = parent.as(ClassDeclSyntax.self) {
//            return classDecl.name.text
//        } else if let enumDecl = parent.as(EnumDeclSyntax.self) {
//            return enumDecl.name.text
//        }
//        currentNode = parent
//    }
//    return nil
// }