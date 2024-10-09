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

@ObservableDefaults
public class Test {
    @DefaultsKey(userDefaultsKey: "firstName")
    public var name: String = "abc"

    @ObservableOnly
    var age: String?
}
