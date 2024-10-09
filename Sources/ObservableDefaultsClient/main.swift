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

@ObservableDefaults // (autoInit: true, ignoreExternalChanges: true, suiteName: "abc")
public class Test {
    @DefaultsKey("firstName")
    public var name: String = "abc"

    @ObservableOnly
    var age: String?
}

let t = Test(userDefaults: .standard, ignoreExternalChanges: false, prefix: "")

import Observation

withObservationTracking {
    let end = Date.now
    print(end)
    print(t.name, "@@")
    print(start.timeIntervalSince1970 - end.timeIntervalSince1970)
} onChange: {
    print("changed")
    Task { @MainActor in
        print(t.name,"^^")
    }
}

let start = Date.now
print(start)
print(t.name, "!!!")
//t.name = "31" //"\(Int.random(in: 0..<100))"
//t.name = t.name
