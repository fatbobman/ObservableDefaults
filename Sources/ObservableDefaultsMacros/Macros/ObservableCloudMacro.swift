//
// ObservableCloudMacro.swift
// Created by Xu Yang on 2025-05-24.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import SwiftSyntax
import SwiftSyntaxMacros

/// A macro that automatically integrates NSUbiquitousKeyValueStore with SwiftUI's Observation
/// framework.
///
/// The `@ObservableCloud` macro generates the necessary code to:
/// - Make the class conform to `Observable` protocol
/// - Automatically synchronize properties with NSUbiquitousKeyValueStore
/// - Handle external cloud store changes via NotificationCenter
/// - Provide precise view updates in SwiftUI
/// - Support development mode for testing without CloudKit container
///
/// Basic usage:
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     var username: String = "Fatbobman"  // Automatically stored in cloud
///     var theme: String = "light"         // Automatically stored in cloud
/// }
/// ```
///
/// With configuration parameters:
/// ```swift
/// @ObservableCloud(
///     autoInit: true,
///     prefix: "myApp_",
///     syncImmediately: true,
///     developmentMode: false,
///     observeFirst: false
/// )
/// class CloudSettings {
///     // Properties automatically managed
/// }
/// ```
///
/// Observe First mode:
/// ```swift
/// @ObservableCloud(observeFirst: true)
/// class CloudSettings {
///     var username: String = "fat"        // Only observable (not stored)
///
///     @CloudBacked
///     var theme: String = "light"         // Observable and stored in cloud
/// }
/// ```
///
/// Development mode for testing:
/// ```swift
/// @ObservableCloud(developmentMode: true)
/// class CloudSettings {
///     // Uses memory storage instead of NSUbiquitousKeyValueStore
///     var setting1: String = "value1"
///     var setting2: Int = 42
/// }
/// ```
public enum ObservableCloudMacros {
    /// The name of the macro as used in source code
    static let name: String = "ObservableCloud"
    /// Parameter for controlling automatic initializer generation
    static let autoInit: String = "autoInit"
    /// Parameter for setting a prefix for all NSUbiquitousKeyValueStore keys
    static let prefix: String = "prefix"
    /// Parameter for enabling Observe First mode
    static let observeFirst: String = "observeFirst"
    /// Parameter for controlling immediate synchronization after each change
    static let syncImmediately: String = "syncImmediately"
    /// Parameter for enabling development mode (uses memory storage instead of cloud)
    static let developmentMode: String = "developmentMode"
}

extension ObservableCloudMacros: MemberMacro {
    // Generates member declarations for the `@ObservableCloud` macro.
    ///
    /// This method creates the following members:
    /// - Observation registrar for SwiftUI integration
    /// - Access and mutation methods for precise view updates
    /// - Configuration properties (prefix, sync behavior, development mode)
    /// - NotificationCenter observer class for external cloud store changes
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

        // Check if the class has @MainActor attribute
        let hasMainActor = classDecl.attributes.contains(where: { attribute in
            if case let .attribute(attr) = attribute,
               let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                return identifierType.name.text == "MainActor"
            }
            return false
        })

        let persistentProperties = classDecl.memberBlock.members
            .compactMap { member -> VariableDeclSyntax? in
                guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                      varDecl.isPersistent
                else {
                    return nil
                }
                return varDecl
            }

        // Generate synchronization control property
        let syncImmediatelySyntax: DeclSyntax =
            """
            /// Controls whether to call `NSUbiquitousKeyValueStore.synchronize()` immediately after setting a value.
            ///
            /// When set to `true`, changes are immediately synchronized with iCloud.
            /// When set to `false`, synchronization follows the system's default behavior.
            ///
            /// - Note: Immediate synchronization can impact performance but ensures data consistency.
            /// - Important: Default value is `false`.
            private var _syncImmediately = \(raw: syncImmediately ? "true" : "false")
            """

        let developementModeSyntax: DeclSyntax =
            """
            /// Determines whether the instance operates in development or production mode.
            ///
            /// - Development mode: Uses memory storage for testing and development, avoiding CloudKit container requirements.
            /// - Production mode: Uses NSUbiquitousKeyValueStore for actual cloud data storage.
            ///
            /// Development mode is automatically enabled when:
            /// - Explicitly set via initializer parameter
            /// - Running in SwiftUI Previews (XCODE_RUNNING_FOR_PREVIEWS environment variable)
            /// - OBSERVABLE_DEFAULTS_DEV_MODE environment variable is set to "true"
            ///
            /// - Important: Default value is `false` (production mode).
            private var _developmentMode: Bool = \(raw: developmentMode)
            public var _developmentMode_: Bool {
                if _developmentMode
                    || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                    || ProcessInfo.processInfo.environment["OBSERVABLE_DEFAULTS_DEV_MODE"] == "true"
                {
                    true
                } else {
                    false
                }
            }
            """

        // Build mapping between properties and their NSUbiquitousKeyValueStore keys
        let metas: [(keyValueStoreKey: String, propertyID: String)] =
            persistentProperties
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
            let caseIndent = index == 0 ? "" : "                "
            // swiftformat:disable all
            if hasMainActor {
                return """
                    \(caseIndent)case prefix + "\(meta.keyValueStoreKey)":
                    \(caseIndent)    MainActor.assumeIsolated {
                    \(caseIndent)        host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
                    \(caseIndent)    }
                    """
            } else {
                return """
                    \(caseIndent)case prefix + "\(meta.keyValueStoreKey)": host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
                    """
            }
            // swiftformat:enable all
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

        // Generate prefix property for NSUbiquitousKeyValueStore keys
        let prefixSyntax: DeclSyntax =
            """
            /// Prefix for the NSUbiquitousKeyValueStore key. The default value is an empty string.
            /// Note: The prefix must not contain '.' characters.
            private var _prefix: String = "\(raw: prefix)"
            """

        // Generate helper methods for value comparison
        let shouldSetValueSyntax: DeclSyntax =
            """
            private nonisolated func shouldSetValue<T>(_ lhs: T, _ rhs: T) -> Bool {
               true
            }

            private nonisolated func shouldSetValue<T: Equatable>(_ lhs: T, _ rhs: T) -> Bool {
               lhs != rhs
            }

            private nonisolated func shouldSetValue<T: AnyObject>(_ lhs: T, _ rhs: T) -> Bool {
               lhs !== rhs
            }

            private nonisolated func shouldSetValue<T: Equatable & AnyObject>(_ lhs: T, _ rhs: T) -> Bool {
                lhs != rhs
            }
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
                } else {
                    #if DEBUG
                    print("Development mode is enabled, using memory storage for testing and development.")
                    #endif
                }
            }
            """

        // Generate NotificationCenter observer class for NSUbiquitousKeyValueStore changes
        let observerFunctionSyntax: DeclSyntax = if hasMainActor {
            """
            private var _cloudObserver: CloudObservation?

            /// Manages NSUbiquitousKeyValueStore change observation for external cloud updates.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class CloudObservation: @unchecked Sendable {
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
                            object: nil,
                            queue: .main,
                            using: cloudStoreDidChange
                        )
                }

                /// Handles cloud store changes from external sources.
                /// - Parameter notification: The notification containing changed keys information
                @Sendable
                private func cloudStoreDidChange(_ notification: Foundation.Notification) {
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
        } else {
            """
            private var _cloudObserver: CloudObservation?

            /// Manages NSUbiquitousKeyValueStore change observation for external cloud updates.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class CloudObservation: @unchecked Sendable {
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
                            object: nil,
                            queue: nil,
                            using: cloudStoreDidChange
                        )
                }

                /// Handles cloud store changes from external sources.
                /// - Parameter notification: The notification containing changed keys information
                @Sendable
                private func cloudStoreDidChange(_ notification: Foundation.Notification) {
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
        }

        return [
            registrarSyntax,
            accessFunctionSyntax,
            withMutationFunctionSyntax,
            prefixSyntax,
            shouldSetValueSyntax,
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
    /// - Properties are automatically marked with `@CloudBacked` to enable
    /// NSUbiquitousKeyValueStore
    /// synchronization
    ///
    /// In Observe First mode (`observeFirst: true`):
    /// - Properties are automatically marked with `@ObservableOnly` unless explicitly marked with
    /// `@CloudBacked`
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
        let (_, _, observeFirst, _, _) = extractProperty(node)
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
                return ["@\(raw: ObservableOnlyMacro.name)"]
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
    /// Extracts parameters from the `@ObservableCloud` macro attribute.
    ///
    /// Supported parameters:
    /// - `autoInit`: Whether to generate an automatic initializer (default: true)
    /// - `prefix`: Prefix for all NSUbiquitousKeyValueStore keys (default: nil, no prefix)
    /// - `observeFirst`: Whether to enable Observe First mode (default: false)
    /// - `syncImmediately`: Whether to call synchronize() immediately after changes (default:
    /// false)
    /// - `developmentMode`: Whether to use memory storage instead of cloud store (default: false)
    ///
    /// - Parameter node: The attribute syntax containing the parameters
    /// - Returns: A tuple containing all extracted parameter values
    static func extractProperty(_ node: AttributeSyntax) -> (
        autoInit: Bool,
        prefix: String,
        observeFirst: Bool,
        syncImmediately: Bool,
        developementMode: Bool)
    {
        var autoInit = true
        var prefix = ""
        var observeFirst = false
        var syncImmediately = false
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
                    let rawPrefix = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content
                        .text ?? ""
                    prefix = rawPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
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
