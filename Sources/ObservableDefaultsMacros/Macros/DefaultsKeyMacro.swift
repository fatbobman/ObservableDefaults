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

// A macro to set the key name for a property in UserDefaults
// By default, ObservableDefaults uses the property name as the key
// If a custom key is set using DefaultsKey, it will be used instead
// When a prefix is set, the key becomes prefix + (custom key or property name)
public struct DefaultsKeyMacro: PeerMacro {
    static let name: String = "DefaultsKey"
    static let key: String = "userDefaultsKey"

    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}
