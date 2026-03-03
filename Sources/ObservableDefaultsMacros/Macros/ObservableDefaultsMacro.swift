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
    /// Parameter for limiting observations to specific UserDefaults instance
    static let limitToInstance: String = "limitToInstance"
    /// Parameter for indicating when project's defaultIsolation is set to MainActor
    static let defaultIsolationIsMainActor: String = "defaultIsolationIsMainActor"
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
    ///   - conformingTo: The protocols the declaration should conform to
    ///   - context: The macro expansion context (unused)
    /// - Returns: An array of generated member declarations
    /// - Throws: Fatal error if declaration is not a class
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifier = declaration.asProtocol(NamedDeclSyntax.self) else { return [] }

        let className =
            IdentifierPatternSyntax(identifier: .init(stringLiteral: "\(identifier.name.trimmed)"))

        // Extract macro parameters
        let (
            autoInit,
            suiteName,
            prefix,
            ignoreExternalChanges,
            observeFirst,
            limitToInstance,
            defaultIsolationIsMainActor,
            suiteNameExpression,
            prefixExpression
        ) = extractProperty(node)

        if suiteName.isEmpty, let suiteNameExpression {
            context.diagnose(
                .stringLiteralRequired(
                    expression: suiteNameExpression,
                    argumentName: ObservableDefaultsMacros.suiteName,
                    attributeName: "@\(ObservableDefaultsMacros.name)"))
        }

        if prefix.isEmpty, let prefixExpression {
            context.diagnose(
                .stringLiteralRequired(
                    expression: prefixExpression,
                    argumentName: ObservableDefaultsMacros.prefix,
                    attributeName: "@\(ObservableDefaultsMacros.name)"))
        }

        // Find all properties that should be persisted to UserDefaults
        guard let classDecl = declaration as? ClassDeclSyntax else {
            fatalError("@ObservableDefaults can only be applied to classes")
        }

        // Check if the class has @MainActor attribute or if defaultIsolation is MainActor
        let hasExplicitMainActor = classDecl.hasExplicitMainActorAttribute
        let hasMainActor = hasExplicitMainActor || defaultIsolationIsMainActor
        // Collect the persisted property metadata once, then derive all external-change
        // support code from that shared source of truth. In observeFirst mode, only
        // explicitly backed properties participate in persistence and notification handling.
        let metas = classDecl.persistentPropertyMetas(
            primaryAttribute: DefaultsBackedMacro.name,
            primaryArgument: DefaultsBackedMacro.key,
            fallbackAttribute: DefaultsKeyMacro.name,
            fallbackArgument: DefaultsKeyMacro.key,
            observeFirst: observeFirst,
            requiredBackedAttribute: DefaultsBackedMacro.name)

        let keyPathMapsSyntax = makeDefaultsKeyPathMapSyntax(className: className, metas: metas)

        let caseCode = makeDefaultsObservationCaseCode(metas: metas, hasMainActor: hasMainActor)
        let monitoredKeysLiteral = makeMonitoredKeysArrayLiteral(metas)

        // Generate observation registrar for SwiftUI integration
        let registrarSyntax = makeObservationRegistrarSyntax()

        // Generate access method for precise view updates
        let accessFunctionSyntax = makeAccessFunctionSyntax(className: className)

        // Generate mutation method for property changes
        let withMutationFunctionSyntax = makeWithMutationFunctionSyntax(className: className)

        // Generate UserDefaults instance (standard or custom suite)
        let userDefaultStoreSyntax: DeclSyntax =
            !suiteName.isEmpty
            ? """
            private var _userDefaults: Foundation.UserDefaults = {
                if let userDefaults = Foundation.UserDefaults(suiteName: "\(raw: suiteName)") {
                    return userDefaults
                } else {
                    let suiteName = "\(raw: suiteName)"
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
        let prefixSyntax: DeclSyntax =
            """
            /// Prefix for the UserDefaults key. The default value is an empty string.
            /// Note: The prefix must not contain '.' characters.
            private var _prefix: String = "\(raw: prefix)"
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

        // Keep the defaults observer wiring as a single subsystem so the generated
        // observation class and its starter stay in sync.
        let observerMembers = makeDefaultsObserverMembers(
            className: className,
            caseCode: caseCode,
            monitoredKeysLiteral: monitoredKeysLiteral,
            hasMainActor: hasMainActor,
            limitToInstance: limitToInstance,
            defaultIsolationIsMainActor: defaultIsolationIsMainActor,
            metas: metas)

        return [
            registrarSyntax,
            accessFunctionSyntax,
            withMutationFunctionSyntax,
            userDefaultStoreSyntax,
            isExternalNotificationDisabledSyntax,
            prefixSyntax,
            keyPathMapsSyntax,
            shouldSetValueSyntax,
        ] + observerMembers + (autoInit ? [initFunctionSyntax] : [])
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
        in _: some MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        let (_, _, _, _, observeFirst, _, _, _, _) = extractProperty(node)
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
    /// - `defaultIsolationIsMainActor`: Whether project's defaultIsolation is MainActor (default: false)
    ///
    /// - Parameter node: The attribute syntax containing the parameters
    /// - Returns: A tuple containing all extracted parameter values
    static func extractProperty(
        _ node: AttributeSyntax
    ) -> (
        autoInit: Bool,
        suiteName: String,
        prefix: String,
        ignoreExternalChanges: Bool,
        observeFirst: Bool,
        limitToInstance: Bool,
        defaultIsolationIsMainActor: Bool,
        invalidSuiteNameExpression: ExprSyntax?,
        invalidPrefixExpression: ExprSyntax?
    ) {
        var autoInit = true
        var suiteName = ""
        var prefix = ""
        var ignoreExternalChanges = false
        var observeFirst = false
        var limitToInstance = true
        var defaultIsolationIsMainActor = false
        var invalidSuiteNameExpression: ExprSyntax?
        var invalidPrefixExpression: ExprSyntax?

        if let argumentList = node.arguments?.as(LabeledExprListSyntax.self) {
            if let value = argumentList.booleanLiteralValue(forLabel: ObservableDefaultsMacros.autoInit) {
                autoInit = value
            }
            if let value = argumentList.booleanLiteralValue(
                forLabel: ObservableDefaultsMacros.ignoreExternalChanges)
            {
                ignoreExternalChanges = value
            }
            if let suiteNameExpression = argumentList.expression(forLabel: ObservableDefaultsMacros.suiteName) {
                if let value = suiteNameExpression.trimmedStringLiteralValue {
                    suiteName = value
                } else {
                    invalidSuiteNameExpression = suiteNameExpression
                }
            }
            if let prefixExpression = argumentList.expression(forLabel: ObservableDefaultsMacros.prefix) {
                if let value = prefixExpression.trimmedStringLiteralValue {
                    prefix = value
                } else {
                    invalidPrefixExpression = prefixExpression
                }
            }
            if let value = argumentList.booleanLiteralValue(
                forLabel: ObservableDefaultsMacros.observeFirst)
            {
                observeFirst = value
            }
            if let value = argumentList.booleanLiteralValue(
                forLabel: ObservableDefaultsMacros.limitToInstance)
            {
                limitToInstance = value
            }
            if let value = argumentList.booleanLiteralValue(
                forLabel: ObservableDefaultsMacros.defaultIsolationIsMainActor)
            {
                defaultIsolationIsMainActor = value
            }
        }
        return (
            autoInit,
            suiteName,
            prefix,
            ignoreExternalChanges,
            observeFirst,
            limitToInstance,
            defaultIsolationIsMainActor,
            invalidSuiteNameExpression,
            invalidPrefixExpression
        )
    }
}
