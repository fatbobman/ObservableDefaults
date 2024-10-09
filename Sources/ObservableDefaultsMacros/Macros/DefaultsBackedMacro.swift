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
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self), // 变量名称
              binding.accessorBlock == nil // 不应该有 get set
        else { return [] }

        // 默认的 key 为参数名
        var keyString: String = identifier.trimmedDescription

        // 是否可以持久化
        guard property.isPersistent else {
            let diagnostic = Diagnostic.variableRequired(property: property)
            context.diagnose(diagnostic)
            return []
        }

        // 必须提供默认值，没有则报错
        if binding.initializer == nil {
            let diagnostic = Diagnostic.initializerRequired(property: property)
            context.diagnose(diagnostic)
            return []
        }

        // 提取变量的类型注解，需要显式标注类型
        guard let typeAnnotation = binding.typeAnnotation else {
            let diagnostic = Diagnostic.explicitTypeAnnotationRequired(property: property)
            context.diagnose(diagnostic)
            return []
        }

        // 检查类型是否为 optional，如果是报告错误(支持 ? ! 和 Optional 三种写法的判断)
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

        // 如果标注了 @Attribute(originalKey:)，使用用户指定的 Key
        if let extractedKey: String = property.attributes.extractValue(forAttribute: DefaultsKeyMacro.name, argument: DefaultsKeyMacro.key) {
            keyString = extractedKey
        }

        let getAccessor: AccessorDeclSyntax =
            """
            get {
                access(keyPath: \\.\(identifier))
                let key = _prefix + "\(raw: keyString)"
                return UserDefaultsWrapper.getValue(key, _\(identifier).0, _userDefaults)
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
        in context: Context
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
            private var _\(raw: identifier.text) = (\(raw: defaultValue),\(raw: defaultValue))
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
