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

public enum ObservableOnlyMacro {
    static let name: String = "ObservableOnly"
}

extension ObservableOnlyMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isObservable,
              let identifier = property.identifier,
              let typeAnnotation = property.bindings.first?.typeAnnotation
        else {
            return []
        }

        guard let binding = property.bindings.first else {
            return []
        }

        let storage: DeclSyntax =
            """
            private var _\(raw: identifier.text)\(typeAnnotation) \(binding.initializer)
            """
        return [storage]
    }
}

extension ObservableOnlyMacro: AccessorMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isObservable,
              let identifier = property.identifier?.trimmed
        else {
            return []
        }

        if property.hasMacroApplication(IgnoreMacro.name) {
            return []
        }

        let getAccessor: AccessorDeclSyntax =
            """
            get {
            access(keyPath: \\.\(identifier))
            return _\(identifier)
            }
            """

        let setAccessor: AccessorDeclSyntax =
            """
            set {
            withMutation(keyPath: \\.\(identifier)) {
            _\(identifier) = newValue
            }
            }
            """

        let modifyAccessor: AccessorDeclSyntax =
            """
            _modify {
            access(keyPath: \\.\(identifier))
                _$observationRegistrar.willSet(self, keyPath: \\.\(identifier))
            defer { _$observationRegistrar.didSet(self, keyPath: \\.\(identifier)) } 
            yield &_\(identifier)
            }
            """

        return [getAccessor, setAccessor, modifyAccessor]
    }
}
