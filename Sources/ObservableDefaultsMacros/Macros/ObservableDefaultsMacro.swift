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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftUI

public enum ObservableDefaultsMacros {
    static let name: String = "ObservableDefaults"
}

extension ObservableDefaultsMacros: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifier = declaration.asProtocol(NamedDeclSyntax.self) else { return [] }

        let className = IdentifierPatternSyntax(identifier: .init(stringLiteral: "\(identifier.name.trimmed)"))

        let (autoInit, suiteName, prefix, ignoreExternalChanges) = extractProperty(node)

        // 遍历所有成员，获取所有 isPersistent 为 true 的成员
        guard let classDecl = declaration as? ClassDeclSyntax else {
            fatalError()
        }
        let persistentProperties = classDecl.memberBlock.members.compactMap { member -> VariableDeclSyntax? in
            // member: MemberBlockItemListSyntax.Element
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.isPersistent
            else {
                return nil
            }
            return varDecl
        }

        let metas: [(userDefaultsKey: String, propertyID: String)] = persistentProperties.map { property in
            let key = property.attributes.extractValue(forAttribute: DefaultsKeyMacro.name, argument: DefaultsKeyMacro.key) ?? property.identifier?.text ?? ""
            let propertyID = property.identifier?.text ?? ""
            return (key, propertyID)
        }

        let addObserverCode = metas.enumerated().map { index, meta in
            let indent = index == 0 ? "" : "        " // 第一行用 0 个空格，其他行用 8 个
            return "\(indent)userDefaults.addObserver(self, forKeyPath: prefix + \"\(meta.userDefaultsKey)\", options: .new, context: nil)"
        }.joined(separator: "\n")

        let caseCode = metas.enumerated().map { index, meta in
            let caseIndent = index == 0 ? "" : "        " // 第一个 case 使用 8 个空格，其他的用 8 个
            let bodyIndent = "            " // 12 个空格用于 case 内的代码
            return """
            \(caseIndent)case prefix + "\(meta.userDefaultsKey)":
            \(bodyIndent)host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
            """
        }.joined(separator: "\n")

        let removeObserverCode = metas.enumerated().map { index, meta in
            let indent = index == 0 ? "" : "        " // 第一行用 0 个空格，其他行用 8 个
            return "\(indent)userDefaults.removeObserver(self, forKeyPath: prefix + \"\(meta.userDefaultsKey)\")"
        }.joined(separator: "\n")

        let registrarSyntax: DeclSyntax =
            """
            internal let _$observationRegistrar = Observation.ObservationRegistrar()
            """

        let accessFunctionSyntax: DeclSyntax =
            """
            internal nonisolated func access<Member>(keyPath: KeyPath<\(className), Member>) {
              _$observationRegistrar.access(self, keyPath: keyPath)
            }
            """

        let withMutationFunctionSyntax: DeclSyntax =
            """
            internal nonisolated func withMutation<Member, T>(keyPath: KeyPath<\(className), Member>, _ mutation: () throws -> T) rethrows -> T {
              try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }
            """

        let userDefaultStoreSyntax: DeclSyntax = suiteName != nil ?
            """
            internal var _userDefaults: Foundation.UserDefaults = {
                if let userDefaults = Foundation.UserDefaults(suiteName: \(raw: suiteName!)) {
                    return userDefaults
                } else {
                    assertionFailure("Failed to create UserDefaults with suiteName 'hello', falling back to UserDefaults.standard.")
                    return Foundation.UserDefaults.standard
                }
            }()
            """
            : """
            internal var _userDefaults: Foundation.UserDefaults = Foundation.UserDefaults.standard
            """

        let isExternalNotificationDisabled = !ignoreExternalChanges ? "true" : "false"
        let isExternalNotificationDisabledSyntax: DeclSyntax =
            """
            internal var _isExternalNotificationDisabled: Bool = \(raw: isExternalNotificationDisabled)
            """

        let prefixStr = prefix != nil ? prefix! : "\"\(className).\""
        let prefixSyntax: DeclSyntax =
            """
            internal var _prefix: String = \(raw: prefixStr)
            """

        let initFunctionSyntax: DeclSyntax =
            """
            public init(
                userDefaults: Foundation.UserDefaults? = nil,
                ignoreExternalChanges: Bool? = nil,
                prefix: String? = nil
            ) {
                if let userDefaults {
                    _userDefaults = userDefaults
                }
                if let ignoreExternalChanges {
                    _isExternalNotificationDisabled = ignoreExternalChanges
                }
                if let prefix {
                    _prefix = prefix
                }
                assert(!_prefix.contains("."), "Prefix '\\(_prefix)' should not contain '.' to avoid KVO issues!")
                if !_isExternalNotificationDisabled {
                    observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix)
                }
            }
            """

        let observerFunctionSyntax: DeclSyntax =
            """
            private var observer: DefaultsObservation?
            class DefaultsObservation: NSObject {
                let host: \(className)
                let userDefaults: Foundation.UserDefaults
                let prefix: String
                init(host: \(className), userDefaults: Foundation.UserDefaults, prefix: String) {
                    self.host = host
                    self.userDefaults = userDefaults
                    self.prefix = prefix
                    super.init()
                    \(raw: addObserverCode)
                }

                override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                    switch keyPath {
                    \(raw: caseCode)
                    default:
                        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                    }
                }

                deinit {
                    \(raw: removeObserverCode)
                }
            }
            """

        return [
            registrarSyntax,
            accessFunctionSyntax,
            withMutationFunctionSyntax,
            userDefaultStoreSyntax,
            isExternalNotificationDisabledSyntax,
            prefixSyntax,
            observerFunctionSyntax,
        ] + (autoInit ? [initFunctionSyntax] : [])
    }
}

extension ObservableDefaultsMacros: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let observableProtocol: DeclSyntax =
            """
                extension \(type.trimmed): Observation.Observable {}
            """

        guard let ext = observableProtocol.as(ExtensionDeclSyntax.self) else { return [] }
        return [ext]
    }
}

extension ObservableDefaultsMacros: MemberAttributeMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        guard let varDecl = member.as(VariableDeclSyntax.self),
              varDecl.isPersistent
        else {
            return []
        }
        return [
            """
            @\(raw: DefaultsBackedMacro.name)
            """,
        ]
    }
}

extension ObservableDefaultsMacros {
    static func allowInit(node: AttributeSyntax, context _: MacroExpansionContext) throws -> Bool {
        guard let argumentList = node.arguments?.as(LabeledExprListSyntax.self) else {
            return false // 如果没有参数，默认返回 false
        }

        // 遍历参数列表
        for argument in argumentList {
            if argument.label?.text == "autoInit",
               let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
            {
                return booleanLiteral.literal.text == "true"
            }
        }
        return false
    }

    static func extractProperty(_ node: AttributeSyntax) -> (
        autoInit: Bool,
        suiteName: String?,
        prefix: String?,
        ignoreExternalChanges: Bool
    ) {
        var autoInit = true
        var suiteName: String?
        var prefix: String?
        var ignoreExternalChanges = false

        if let argumentList = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in argumentList {
                if argument.label?.text == "autoInit",
                   let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    autoInit = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == "ignoreExternalChanges",
                          let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    ignoreExternalChanges = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == "suiteName",
                          let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
                {
                    suiteName = stringLiteral.trimmedDescription
                } else if argument.label?.text == "prefix",
                          let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
                {
                    prefix = stringLiteral.trimmedDescription
                }
            }
        }
        return (autoInit, suiteName, prefix, ignoreExternalChanges)
    }
}

// extension ObservableDefaultsMacros {
//    static func extractVarProperties(_ declaration: some DeclGroupSyntax) -> [VariableDeclSyntax] {
//        return declaration.memberBlock.members.compactMap { member in
//            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
//                  varDecl.bindingSpecifier.text == "var",
//                  varDecl.bindings.count == 1,
//                  varDecl.bindings.first?.accessorBlock == nil
//            else {
//                return nil
//            }
//            return varDecl
//        }
//    }
//
//    static func generatePrivateLetDeclarations(_ varProperties: [VariableDeclSyntax]) -> [DeclSyntax] {
//        return varProperties.compactMap { varDecl in
//            guard let binding = varDecl.bindings.first,
//                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
//                  let type = binding.typeAnnotation?.type
//            else {
//                return nil
//            }
//
//            return DeclSyntax("private var _\(identifier): \(type)")
//        }
//    }
// }
