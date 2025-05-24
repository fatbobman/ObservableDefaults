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
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct UserDefaultsObservationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefaultsBackedMacro.self,
        DefaultsKeyMacro.self,
        ObservableDefaultsMacros.self,
        IgnoreMacro.self,
        ObservableOnlyMacro.self,
        CloudBackedMacro.self,
        CloudKeyMacro.self,
    ]
}
