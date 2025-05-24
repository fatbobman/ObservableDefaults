//
// ObservableCloudMacro.swift
// Created by Xu Yang on 2025-05-24.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import SwiftSyntax
import SwiftSyntaxMacros

public enum ObservableCloudMacros {
    /// The name of the macro as used in source code
    static let name: String = "ObservableCloud"
    /// Parameter for controlling automatic initializer generation
    static let autoInit: String = "autoInit"
    /// Parameter for setting a prefix for all NSUbiquitousKeyValueStore keys
    static let prefix: String = "prefix"
    /// Parameter for enabling Observe First mode
    static let observeFirst: String = "observeFirst"
    /// 是否在每次设置后立即调用 `NSUbiquitousKeyValueStore.synchronize()`
    static let syncImmediately: String = "syncImmediately"
    /// 持久化模式，使用 NSUbiquitousKeyValueStore 或者内存中存储（用于调试，避免崩溃）
    static let developmentMode: String = "developmentMode"
}

extension ObservableCloudMacros: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        guard let identifier = declaration.asProtocol(NamedDeclSyntax.self) else { return [] }

        let className =
            IdentifierPatternSyntax(identifier: .init(stringLiteral: "\(identifier.name.trimmed)"))

        // Extract macro parameters
        let (
            autoInit,
            prefix,
            _,
            syncImmediately,
            developmentMode) = extractProperty(node)

        // Find all properties that should be persisted to NSUbiquitousKeyValueStore
        guard let classDecl = declaration as? ClassDeclSyntax else {
            fatalError("@ObservableCloud can only be applied to classes")
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

        // syncImmediately is used to control whether to call
        // `NSUbiquitousKeyValueStore.synchronize()`
        // immediately after setting a value. This is useful for ensuring that changes are
        let syncImmediatelySyntax: DeclSyntax =
            """
            /// syncImmediately is used to control whether to call `NSUbiquitousKeyValueStore.synchronize()`
            /// immediately after setting a value. This is useful for ensuring that changes are
            private var _syncImmediately = \(raw: syncImmediately ? "true" : "false")
            """

        let developementModeSyntax: DeclSyntax =
            """
            /// The CloudKit requirement mode determines whether the instance operates in development or production mode.
            ///
            /// - Development mode: Uses memory storage for testing and development.
            /// - Production mode: Uses NSUbiquitousKeyValueStore for production data storage.
            private var _developmentMode: Bool = \(raw: developmentMode)
            public var _developmentMode_: Bool {
                if _developmentMode
                    || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                    || ProcessInfo.processInfo.environment["com.observableDefaults.developmentMode"] == "true"
                {
                    true
                } else {
                    false
                }
            }
            """

        // Build mapping between properties and their UserDefaults keys
        let metas: [(keyValueStoreKey: String, propertyID: String)] = persistentProperties
            .map { property in
                let key =
                    property.attributes.extractValue(
                        forAttribute: CloudBackedMacro.name,
                        argument: CloudBackedMacro.key) ??
                    property.attributes.extractValue(
                        forAttribute: CloudKeyMacro.name,
                        argument: CloudKeyMacro.key) ?? property.identifier?.text ?? ""
                let propertyID = property.identifier?.text ?? ""
                return (key, propertyID)
            }

        let caseCode = metas.enumerated().map { index, meta in
            let caseIndent = index == 0 ? "" : "        "
            return """
                \(caseIndent)case prefix + "\(meta.keyValueStoreKey)":
                \(caseIndent)     host._$observationRegistrar.withMutation(of: host,
                \(caseIndent)                   keyPath: \\.\(meta.propertyID)) {}
                """
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

        // Generate prefix property for UserDefaults keys
        let prefixStr = prefix != nil ? prefix! : ""
        let emptyStr = prefixStr == "" ? "\"\"" : ""
        let prefixSyntax: DeclSyntax =
            """
            /// Prefix for the NSUbiquitousKeyValueStore key. The default value is an empty string.
            /// Note: The prefix must not contain '.' characters.
            private var _prefix: String = \(raw: prefixStr)\(raw: emptyStr)
            """

        // Generate initializer when autoInit is enabled
        let initFunctionSyntax: DeclSyntax =
            """
            public init(
                prefix: String? = nil,
                syncImmediately: Bool = false,
                developmentMode: Bool = false
            ) {
                if let prefix {
                    _prefix = prefix
                }
                _syncImmediately = syncImmediately
                _developmentMode = developmentMode
                assert(!_prefix.contains("."), "Prefix '\\(_prefix)' should not contain '.' to avoid KVO issues!")
                if !_developmentMode_ {
                    _cloudObserver = CloudObservation(host: self, prefix: _prefix)
                }
            }
            """

        // Generate KVO observer class for NSUbiquitousKeyValueStore  changes
        let observerFunctionSyntax: DeclSyntax =
            """
            private var _cloudObserver: CloudObservation?

            /// The observation registrar manages NSUbiquitousKeyValueStore change observation.
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private class CloudObservation {
                let host: \(className)
                let prefix: String

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - prefix: The prefix for the NSUbiquitousKeyValueStore keys
                init(host: \(className), prefix: String) {
                    self.host = host
                    self.prefix = prefix
                    NotificationCenter.default
                        .addObserver(
                            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                            object: NSUbiquitousKeyValueStore.default,
                            queue: nil,
                            using: cloudStoreDidChange
                        )

                }

                private func cloudStoreDidChange(_ notification: Notification) {
                    guard let userInfo = notification.userInfo,
                        let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
                    else {
                        return
                    }

                    for key in changedKeys {
                        switch key {
                             \(raw: caseCode)
                            default:
                                break
                        }
                    }
                }

                deinit {
                    NotificationCenter.default.removeObserver(self)
                }
            }
            """

        return [
            registrarSyntax,
            accessFunctionSyntax,
            withMutationFunctionSyntax,
            prefixSyntax,
            syncImmediatelySyntax,
            developementModeSyntax,
            observerFunctionSyntax,
        ] + (autoInit ? [initFunctionSyntax] : [])
    }
}

extension ObservableCloudMacros: ExtensionMacro {
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

extension ObservableCloudMacros: MemberAttributeMacro {
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
            // @CloudBacked or @ObservableOnly
            if !varDecl.hasAttribute(named: CloudBackedMacro.name),
               !varDecl.hasAttribute(named: ObservableOnlyMacro.name)
            {
                return ["@\(raw: CloudBackedMacro.name)"]
            }
        } else {
            // In standard mode, add @CloudBacked to persistent properties
            if varDecl.isPersistent, !varDecl.hasAttribute(named: CloudBackedMacro.name) {
                return ["@\(raw: CloudBackedMacro.name)"]
            }
        }

        return []
    }
}

extension ObservableCloudMacros {
    static func extractProperty(_ node: AttributeSyntax) -> (
        autoInit: Bool,
        prefix: String?,
        observeFirst: Bool,
        syncImmediately: Bool,
        developementMode: Bool)
    {
        var autoInit = true
        var prefix: String?
        var observeFirst = false
        var syncImmediately = false
        // 默认为生产模式，使用 NSUbiquitousKeyValueStore
        var developmentMode = false

        if let argumentList = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in argumentList {
                if argument.label?.text == ObservableCloudMacros.autoInit,
                   let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    autoInit = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == ObservableCloudMacros.prefix,
                          let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
                {
                    prefix = stringLiteral.trimmedDescription
                } else if argument.label?.text == ObservableCloudMacros.observeFirst,
                          let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    observeFirst = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == ObservableCloudMacros.syncImmediately,
                          let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    syncImmediately = booleanLiteral.literal.text == "true"
                } else if argument.label?.text == ObservableCloudMacros.developmentMode,
                          let booleanLiteral = argument.expression.as(BooleanLiteralExprSyntax.self)
                {
                    developmentMode = booleanLiteral.literal.text == "true"
                }
            }
        }
        return (autoInit, prefix, observeFirst, syncImmediately, developmentMode)
    }
}
