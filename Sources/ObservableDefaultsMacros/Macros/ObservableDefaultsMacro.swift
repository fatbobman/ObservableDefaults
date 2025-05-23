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

/// A macro that automatically integrates UserDefaults with SwiftUI's Observation framework.
///
/// The `@ObservableDefaults` macro generates the necessary code to:
/// - Make the class conform to `Observable` protocol
/// - Automatically synchronize properties with UserDefaults
/// - Handle external UserDefaults changes via KVO
/// - Provide precise view updates in SwiftUI
///
/// Basic usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Automatically stored in UserDefaults
///     var age: Int = 20              // Automatically stored in UserDefaults
/// }
/// ```
///
/// With configuration parameters:
/// ```swift
/// @ObservableDefaults(
///     autoInit: true,
///     ignoreExternalChanges: false,
///     suiteName: "group.myapp",
///     prefix: "myApp_",
///     observeFirst: false
/// )
/// class Settings {
///     // Properties automatically managed
/// }
/// ```
///
/// Observe First mode:
/// ```swift
/// @ObservableDefaults(observeFirst: true)
/// class Settings {
///     var name: String = "fat"          // Only observable (not stored)
///
///     @DefaultsBacked
///     var age: Int = 109               // Observable and stored in UserDefaults
/// }
/// ```
public enum ObservableDefaultsMacros {
    /// The name of the macro as used in source code
    static let name: String = "ObservableDefaults"
    /// Parameter for controlling automatic initializer generation
    static let autoInit: String = "autoInit"
    /// Parameter for controlling response to external UserDefaults changes
    static let ignoreExternalChanges: String = "ignoreExternalChanges"
    /// Parameter for specifying custom UserDefaults suite name
    static let suiteName: String = "suiteName"
    /// Parameter for setting a prefix for all UserDefaults keys
    static let prefix: String = "prefix"
    /// Parameter for enabling Observe First mode
    static let observeFirst: String = "observeFirst"
}

extension ObservableDefaultsMacros: MemberMacro {
    /// Generates member declarations for the `@ObservableDefaults` macro.
    ///
    /// This method creates the following members:
    /// - Observation registrar for SwiftUI integration
    /// - Access and mutation methods for precise view updates
    /// - UserDefaults instance (standard or custom suite)
    /// - Configuration properties (prefix, external change handling)
    /// - KVO observer class for external UserDefaults changes
    /// - Optional initializer (when autoInit is true)
    ///
    /// - Parameters:
    ///   - node: The attribute syntax containing macro parameters
    ///   - declaration: The class declaration to add members to
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array of generated member declarations
    /// - Throws: Fatal error if declaration is not a class
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        guard let identifier = declaration.asProtocol(NamedDeclSyntax.self) else { return [] }

        let className =
            IdentifierPatternSyntax(identifier: .init(stringLiteral: "\(identifier.name.trimmed)"))

        // Extract macro parameters
        let (autoInit, suiteName, prefix, ignoreExternalChanges, _) = extractProperty(node)

        // Find all properties that should be persisted to UserDefaults
        guard let classDecl = declaration as? ClassDeclSyntax else {
            fatalError("@ObservableDefaults can only be applied to classes")
        }
        let persistentProperties = classDecl.memberBlock.members
            .compactMap { member -> VariableDeclSyntax? in
                guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                      varDecl.isPersistent
                else {
                    return nil
                }
                return varDecl
            }

        // Build mapping between properties and their UserDefaults keys
        let metas: [(userDefaultsKey: String, propertyID: String)] = persistentProperties
            .map { property in
                let key =
                    property.attributes.extractValue(
                        forAttribute: DefaultsBackedMacro.name,
                        argument: DefaultsBackedMacro.key) ??
                    property.attributes.extractValue(
                        forAttribute: DefaultsKeyMacro.name,
                        argument: DefaultsKeyMacro.key) ?? property.identifier?.text ?? ""
                let propertyID = property.identifier?.text ?? ""
                return (key, propertyID)
            }

        // Generate keyPath mapping for external change handling
        let keyPathMaps = "[" + metas
            .map { "\\\(className).\($0.propertyID): \"\($0.userDefaultsKey)\"" }
            .joined(separator: ", ") + "]"
        let keyPathMapsSyntax: DeclSyntax =
            """
            private let _defaultsKeyPathMap: [PartialKeyPath<\(raw: className)>: String] = \(
                raw: keyPathMaps)
            private var _ignoredKeyPathsForExternalUpdates: [PartialKeyPath<\(raw: className)>] = []
            """

        // Generate KVO observer code for external UserDefaults changes
        let addObserverCode = metas.enumerated().map { index, meta in
            let indent = index == 0 ? "" : "        "
            return "\(indent)if !observableKeysBlacklist.contains(prefix + \"\(meta.userDefaultsKey)\"){ userDefaults.addObserver(self, forKeyPath: prefix + \"\(meta.userDefaultsKey)\", options: .new, context: nil) }"
        }.joined(separator: "\n")

        let caseCode = metas.enumerated().map { index, meta in
            let caseIndent = index == 0 ? "" : "        "
            let bodyIndent = "            "
            return """
                \(caseIndent)case prefix + "\(meta.userDefaultsKey)":
                \(bodyIndent)host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta
                .propertyID)) {}
                """
        }.joined(separator: "\n")

        let removeObserverCode = metas.enumerated().map { index, meta in
            let indent = index == 0 ? "" : "        "
            return "\(indent)if !observableKeysBlacklist.contains(prefix + \"\(meta.userDefaultsKey)\"){ userDefaults.removeObserver(self, forKeyPath: prefix + \"\(meta.userDefaultsKey)\") }"
        }.joined(separator: "\n")

        // Generate observation registrar for SwiftUI integration
        let registrarSyntax: DeclSyntax =
            """
            internal let _$observationRegistrar = Observation.ObservationRegistrar()
            """

        // Generate access method for precise view updates
        let accessFunctionSyntax: DeclSyntax =
            """
            internal nonisolated func access<Member>(keyPath: KeyPath<\(className), Member>) {
              _$observationRegistrar.access(self, keyPath: keyPath)
            }
            """

        // Generate mutation method for property changes
        let withMutationFunctionSyntax: DeclSyntax =
            """
            /// Performs a mutation on the specified keyPath and notifies observers.
            /// - Parameters:
            ///   - keyPath: The key path to the property being mutated
            ///   - mutation: The mutation closure to execute
            /// - Returns: The result of the mutation closure
            internal nonisolated func withMutation<Member, T>(keyPath: KeyPath<\(
                className), Member>, _ mutation: () throws -> T) rethrows -> T {
              try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }
            """

        // Generate UserDefaults instance (standard or custom suite)
        let userDefaultStoreSyntax: DeclSyntax = suiteName != nil ?
            """
            private var _userDefaults: Foundation.UserDefaults = {
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
                private var _userDefaults: Foundation.UserDefaults = Foundation.UserDefaults.standard
                """

        // Generate external notification control property
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
            private var _isExternalNotificationDisabled: Bool = \(
                raw: isExternalNotificationDisabled)
            """

        // Generate prefix property for UserDefaults keys
        let prefixStr = prefix != nil ? prefix! : ""
        let emptyStr = prefixStr == "" ? "\"\"" : ""
        let prefixSyntax: DeclSyntax =
            """
            /// Prefix for the UserDefaults key. The default value is an empty string.
            /// Note: The prefix must not contain '.' characters.
            private var _prefix: String = \(raw: prefixStr)\(raw: emptyStr)
            """

        // Generate initializer when autoInit is enabled
        let initFunctionSyntax: DeclSyntax =
            """
            public init(
                userDefaults: Foundation.UserDefaults? = nil,
                ignoreExternalChanges: Bool? = nil,
                prefix: String? = nil,
                ignoredKeyPathsForExternalUpdates: [PartialKeyPath<\(raw: className)>] = []
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
                _ignoredKeyPathsForExternalUpdates = ignoredKeyPathsForExternalUpdates
                assert(!_prefix.contains("."), "Prefix '\\(_prefix)' should not contain '.' to avoid KVO issues!")
                if !_isExternalNotificationDisabled {
                    observerStarter(observableKeysBlacklist: ignoredKeyPathsForExternalUpdates)
                }
            }
            """

        // Generate KVO observer class for external UserDefaults changes
        let observerFunctionSyntax: DeclSyntax =
            """
            private var observer: DefaultsObservation?

            /// The observation registrar manages UserDefaults change observation.
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private class DefaultsObservation: NSObject {
                let host: \(className)
                let userDefaults: Foundation.UserDefaults
                let prefix: String
                let observableKeysBlacklist: [String]

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - userDefaults: The UserDefaults instance to monitor
                ///   - prefix: The key prefix for UserDefaults keys
                ///   - observableKeysBlacklist: Keys to exclude from observation
                init(host: \(
                    className), userDefaults: Foundation.UserDefaults, prefix: String, observableKeysBlacklist: [String]) {
                    self.host = host
                    self.userDefaults = userDefaults
                    self.prefix = prefix
                    self.observableKeysBlacklist = observableKeysBlacklist
                    super.init()
                    \(raw: addObserverCode)
                }

                /// Observes value changes for UserDefaults keys.
                /// - Parameters:
                ///   - keyPath: The key path that changed
                ///   - object: The object being observed
                ///   - change: The change dictionary
                ///   - context: The observation context
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

        // Generate observer starter method
        let observerStarterSyntax: DeclSyntax =
            """
            private func observerStarter(observableKeysBlacklist: [PartialKeyPath<\(
                raw: className)>] = []) {
                let keyList = observableKeysBlacklist.compactMap{ _defaultsKeyPathMap[$0] }
                observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix, observableKeysBlacklist: keyList)
            }
            """

        return [
            registrarSyntax,
            accessFunctionSyntax,
            withMutationFunctionSyntax,
            userDefaultStoreSyntax,
            isExternalNotificationDisabledSyntax,
            prefixSyntax,
            keyPathMapsSyntax,
            observerFunctionSyntax,
            observerStarterSyntax,
        ] + (autoInit ? [initFunctionSyntax] : [])
    }
}

extension ObservableDefaultsMacros: ExtensionMacro {
    /// Generates an extension that makes the class conform to the `Observable` protocol.
    ///
    /// This enables SwiftUI integration and precise view updates when properties change.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax (unused)
    ///   - declaration: The class declaration (unused)
    ///   - type: The type to generate the extension for
    ///   - protocols: The protocols to conform to (unused)
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array containing the Observable conformance extension
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext) throws -> [ExtensionDeclSyntax]
    {
        let observableProtocol: DeclSyntax =
            """
                extension \(type.trimmed): Observation.Observable {}
            """

        guard let ext = observableProtocol.as(ExtensionDeclSyntax.self) else { return [] }
        return [ext]
    }
}

extension ObservableDefaultsMacros: MemberAttributeMacro {
    /// Automatically applies appropriate macros to properties based on the operation mode.
    ///
    /// In standard mode:
    /// - Properties are automatically marked with `@DefaultsBacked` to enable UserDefaults
    /// synchronization
    ///
    /// In Observe First mode (`observeFirst: true`):
    /// - Properties are automatically marked with `@ObservableOnly` unless explicitly marked with
    /// `@DefaultsBacked`
    ///
    /// - Parameters:
    ///   - node: The attribute syntax containing macro parameters
    ///   - declaration: The class declaration (unused)
    ///   - member: The member declaration to potentially add attributes to
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array of attribute syntax to apply to the member
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax]
    {
        let (_, _, _, _, observeFirst) = extractProperty(node)
        guard let varDecl = member.as(VariableDeclSyntax.self),
              varDecl.isObservable
        else {
            return []
        }

        if observeFirst {
            // In Observe First mode, only add @ObservableOnly if not already marked with
            // @DefaultsBacked or @ObservableOnly
            if !varDecl.hasAttribute(named: DefaultsBackedMacro.name),
               !varDecl.hasAttribute(named: ObservableOnlyMacro.name)
            {
                return ["@\(raw: ObservableOnlyMacro.name)"]
            }
        } else {
            // In standard mode, add @DefaultsBacked to persistent properties
            if varDecl.isPersistent, !varDecl.hasAttribute(named: DefaultsBackedMacro.name) {
                return ["@\(raw: DefaultsBackedMacro.name)"]
            }
        }

        return []
    }
}

extension ObservableDefaultsMacros {
    /// Extracts parameters from the `@ObservableDefaults` macro attribute.
    ///
    /// Supported parameters:
    /// - `autoInit`: Whether to generate an automatic initializer (default: true)
    /// - `suiteName`: Custom UserDefaults suite name (default: nil, uses standard)
    /// - `prefix`: Prefix for all UserDefaults keys (default: nil, no prefix)
    /// - `ignoreExternalChanges`: Whether to ignore external UserDefaults changes (default: false)
    /// - `observeFirst`: Whether to enable Observe First mode (default: false)
    ///
    /// - Parameter node: The attribute syntax containing the parameters
    /// - Returns: A tuple containing all extracted parameter values
    static func extractProperty(_ node: AttributeSyntax) -> (
        autoInit: Bool,
        suiteName: String?,
        prefix: String?,
        ignoreExternalChanges: Bool,
        observeFirst: Bool)
    {
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
