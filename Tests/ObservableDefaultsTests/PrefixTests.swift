//
//  ------------------------------------------------
//  Original project: ObservableDefaults
//  Created on 2025/7/11 by Fatbobman(东坡肘子)
//  X: @fatbobman
//  Mastodon: @fatbobman@mastodon.social
//  GitHub: @fatbobman
//  Blog: https://fatbobman.com
//  ------------------------------------------------
//  Copyright © 2025-present Fatbobman. All rights reserved.
		

import Foundation
import ObservableDefaults
import Observation
import Testing


@ObservableCloud(prefix: "abc", developmentMode:true)
class Test1 {
    var name = "abc"
}

@ObservableDefaults(prefix: "myApp_")
class Test2 {
    var username = "default"
}

@ObservableDefaults(suiteName: "group.testapp", prefix: "suite_")
class Test3 {
    var setting = "value"
}

@ObservableDefaults(suiteName: "group.testapp")
class Test4 {
    var config = "default"
}

@ObservableDefaults(suiteName: "", prefix: "")
class Test5 {
    var emptyParams = "test"
}

@ObservableCloud(prefix: "")
class Test6 {
    var emptyPrefix = "cloud"
}

@Test(.testMode)
func prefixCloud() {
    let test = Test1()
    test.name = "test value"
    #expect(test.name == "test value")
}

@Test(.testMode)
func prefixDefaults() {
    let test = Test2()
    test.username = "newUser"
    #expect(test.username == "newUser")
}

@Test(.testMode)
func suiteNameWithPrefix() {
    let test = Test3()
    test.setting = "updated"
    #expect(test.setting == "updated")
}

@Test(.testMode)
func suiteNameOnly() {
    let test = Test4()
    test.config = "modified"
    #expect(test.config == "modified")
}

@Test(.testMode)
func emptyParameters() {
    let test = Test5()
    test.emptyParams = "changed"
    #expect(test.emptyParams == "changed")
}

@Test(.testMode)
func emptyPrefixCloud() {
    let test = Test6()
    test.emptyPrefix = "updated"
    let value = test.emptyPrefix == "updated"
    #expect(test.emptyPrefix == "updated")
}
