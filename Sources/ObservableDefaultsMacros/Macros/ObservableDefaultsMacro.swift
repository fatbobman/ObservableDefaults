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

public enum ObservableDefaultsMacros {
    static let name: String = "ObservableDefaults"
    static let autoInit: String = "autoInit"
    static let ignoreExternalChanges: String = "ignoreExternalChanges"
    static let suiteName: String = "suiteName"
    static let prefix: String = "prefix"
    static let observeFirst: String = "observeFirst"
}

extension ObservableDefaultsMacros: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifier = declaration.asProtocol(NamedDeclSyntax.self) else { return [] }

        let className = IdentifierPatternSyntax(identifier: .init(stringLiteral: "\(identifier.name.trimmed)"))

        let (autoInit, suiteName, prefix, ignoreExternalChanges, _) = extractProperty(node)

        // Traverse all members and get all members with isPersistent set to true
        guard let classDecl = declaration as? ClassDeclSyntax else {
            fatalError()
        }
        let persistentProperties = classDecl.memberBlock.members.compactMap { member -> VariableDeclSyntax? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.isPersistent
            else {
                return nil
            }
            return varDecl
        }

        let metas: [(userDefaultsKey: String, propertyID: String)] = persistentProperties.map { property in
            let key =
                property.attributes.extractValue(forAttribute: DefaultsBackedMacro.name, argument: DefaultsBackedMacro.key) ??
                property.attributes.extractValue(forAttribute: DefaultsKeyMacro.name, argument: DefaultsKeyMacro.key) ?? property.identifier?.text ?? ""
            let propertyID = property.identifier?.text ?? ""
            return (key, propertyID)
        }

        // Add observer code
        // To align, the first line uses 0 spaces, and the others use 8 spaces. A better method has not been found yet
        let addObserverCode = metas.enumerated().map { index, meta in
            let indent = index == 0 ? "" : "        "
            return "\(indent)userDefaults.addObserver(self, forKeyPath: prefix + \"\(meta.userDefaultsKey)\", options: .new, context: nil)"
        }.joined(separator: "\n")

        let caseCode = metas.enumerated().map { index, meta in
            let caseIndent = index == 0 ? "" : "        "
            let bodyIndent = "            "
            return """
            \(caseIndent)case prefix + "\(meta.userDefaultsKey)":
            \(bodyIndent)host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
            """
        }.joined(separator: "\n")

        let removeObserverCode = metas.enumerated().map { index, meta in
            let indent = index == 0 ? "" : "        "
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
                    let suiteName = \(raw: suiteName ?? "")
                    assertionFailure("Failed to create UserDefaults with suiteName: \\(suiteName), falling back to UserDefaults.standard.")
                    return Foundation.UserDefaults.standard
                }
            }()
            """
            : """
            internal var _userDefaults: Foundation.UserDefaults = Foundation.UserDefaults.standard
            """

        let isExternalNotificationDisabled = ignoreExternalChanges ? "true" : "false"
        let isExternalNotificationDisabledSyntax: DeclSyntax =
            """
            /// Determines whether the instance responds to UserDefaults modifications made externally.
            /// When set to `true`, the instance ignores notifications from changes made to UserDefaults
            /// by other parts of the application or other processes.
            /// When set to `false`, the instance will respond to all UserDefaults changes, regardless of their origin.
            ///
            /// - Note: This flag is particularly useful in scenarios where you want to avoid
            ///   recursive or unnecessary updates when the instance itself is modifying UserDefaults.
            ///
            /// - Important: Default value is `false`.
            internal var _isExternalNotificationDisabled: Bool = \(raw: isExternalNotificationDisabled)
            """

        let prefixStr = prefix != nil ? prefix! : ""
        let emptyStr = prefixStr == "" ? "\"\"" : ""
        let prefixSyntax: DeclSyntax =
            """
            /// Prefix for the UserDefaults key. The default value is an empty string.
            /// Note: The prefix must not contain '.' characters.
            internal var _prefix: String = \(raw: prefixStr)\(raw: emptyStr)
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
                    observerStarter()
                }
            }
            """

        let observerFunctionSyntax: DeclSyntax =
            """
            private var observer: DefaultsObservation?

            /// The observation registrar is used to manage the observation of changes to UserDefaults.
            /// It ensures that the observer is properly registered and deregistered when the instance is created and deinitialized.
            /// The registrar is accessed through the `_$observationRegistrar` property.
            ///
            /// - Note: This property is internal and can be accessed within the same module.
            private class DefaultsObservation: NSObject {
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
        let observerStarterSyntax: DeclSyntax =
            """
            private func observerStarter() {
                observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix)
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
            observerStarterSyntax,
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
        of node: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        let (_, _, _, _, observeFirst) = extractProperty(node)
        guard let varDecl = member.as(VariableDeclSyntax.self),
              varDecl.isObservable
        else {
            return []
        }

        if observeFirst {
            if !varDecl.hasAttribute(named: DefaultsBackedMacro.name) && !varDecl.hasAttribute(named: ObservableOnlyMacro.name) {
                return ["@\(raw: ObservableOnlyMacro.name)"]
            }
        } else {
            if varDecl.isPersistent && !varDecl.hasAttribute(named: DefaultsBackedMacro.name) {
                return ["@\(raw: DefaultsBackedMacro.name)"]
            }
        }

        return []
    }
}

extension ObservableDefaultsMacros {
    /// Extract the parameters from the attribute syntax
    /// - Parameters:
    ///   - node: The attribute syntax
    /// - Returns: A tuple containing the parameters
    static func extractProperty(_ node: AttributeSyntax) -> (
        autoInit: Bool,
        suiteName: String?,
        prefix: String?,
        ignoreExternalChanges: Bool,
        observeFirst: Bool
    ) {
        var autoInit = true
        var suiteName: String?
        var prefix: String?
        var ignoreExternalChanges = false
        var observeFirst = false

        if let argumentList = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in argumentList {
                if argument.label?.text == ObservableDefaultsMacros.autoInit,
                   let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    autoInit = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == ObservableDefaultsMacros.ignoreExternalChanges,
                          let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    ignoreExternalChanges = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == ObservableDefaultsMacros.suiteName,
                          let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
                {
                    suiteName = stringLiteral.trimmedDescription
                } else if argument.label?.text == ObservableDefaultsMacros.prefix,
                          let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
                {
                    prefix = stringLiteral.trimmedDescription
                } else if argument.label?.text == ObservableDefaultsMacros.observeFirst,
                          let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    observeFirst = booleanLiteral.literal.text == "true"
                }
            }
        }
        return (autoInit, suiteName, prefix, ignoreExternalChanges, observeFirst)
    }
}
