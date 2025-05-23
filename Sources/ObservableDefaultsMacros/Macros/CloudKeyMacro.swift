//
// CloudKeyMacro.swift
// Created by Xu Yang on 2025-05-23.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import SwiftSyntax
import SwiftSyntaxMacros

public struct CloudKeyMacro: PeerMacro {
    /// The name of the macro as used in source code
    static let name: String = "CloudKey"
    /// The parameter name for specifying the custom NSUbiquitousKeyValueStore key
    static let key: String = "keyValueStoreKey"

    /// Provides peer declarations for the `@CloudKey` macro.
    ///
    /// This macro is a marker macro that doesn't generate additional code.
    /// Instead, it provides metadata that is read by the `@CloudBacked` macro
    /// to determine the custom NSUbiquitousKeyValueStore key for a property.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node (unused)
    ///   - declaration: The declaration this macro is attached to (unused)
    ///   - context: The macro expansion context (unused)
    /// - Returns: An empty array as this macro doesn't generate peer declarations
    /// - Throws: No errors are thrown in this implementation
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
        in _: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        // This is a marker macro that provides metadata for other macros
        // No peer declarations are generated
        []
    }
}
