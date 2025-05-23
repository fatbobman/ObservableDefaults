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
import ObservableDefaults

// swiftlint:disable missing_docs

/// Test1 is an example of using Observe Last Mode
/// In this mode, all properties are observed and persisted in UserDefaults
@ObservableDefaults
public class Test1 {
    @DefaultsKey(userDefaultsKey: "firstName")
    // Automatically adds @DefaultsBacked
    public var name: String = "fat"

    // Automatically adds @DefaultsBacked
    public var age = 109

    // Only observes, not persisted in UserDefaults
    @ObservableOnly
    public var height = 190

    // Not observable and not persisted
    @Ignore
    public var weight = 10
}

/// Test2 is an example of using Observe First Mode
/// In this mode, only properties that need to be persisted require the use of @DefaultsBacked
@ObservableDefaults(observeFirst: true) // Observe First Mode
public class Test2 {
    // Automatically adds @ObservabeOnly
    public var name: String = "fat"

    // Automatically adds @ObservabeOnly
    public var age = 109

    // In Observe First Mode, only properties that need to be persisted require the use of
    // @DefaultsBacked for annotation, and userDefaultsKey can be set within it
    @DefaultsBacked(userDefaultsKey: "myHeight")
    public var height = 190

    // Not observable and not persisted
    @Ignore
    public var weight = 10
}

// swiftlint:enable missing_docs
