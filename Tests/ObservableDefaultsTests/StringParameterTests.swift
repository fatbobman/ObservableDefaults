//
//  StringParameterTests.swift
//  Tests for String parameter handling in ObservableDefaults and ObservableCloud macros
//

import Foundation
import ObservableDefaults
import Testing

// Test various combinations of string parameters

@ObservableCloud(developmentMode: true)
class CloudNoParams {
    var cloudValue1 = "default"
}

@ObservableCloud(prefix: "app_", developmentMode: true)
class CloudWithPrefix {
    var cloudValue2 = "default"
}

@ObservableCloud(prefix: "", developmentMode: true)
class CloudEmptyPrefix {
    var cloudValue3 = "default"
}

@ObservableDefaults
class DefaultsNoParams {
    var defaultsValue1 = "default"
}

@ObservableDefaults(prefix: "myapp_")
class DefaultsWithPrefix {
    var defaultsValue2 = "default"
}

@ObservableDefaults(suiteName: "group.test")
class DefaultsWithSuite {
    var defaultsValue3 = "default"
}

@ObservableDefaults(suiteName: "group.test", prefix: "suite_")
class DefaultsWithBoth {
    var defaultsValue4 = "default"
}

@ObservableDefaults(suiteName: "", prefix: "")
class DefaultsEmptyParams {
    var defaultsValue5 = "default"
}

@Test(.testMode)
func cloudParameterTests() {
    let noParams = CloudNoParams()
    let withPrefix = CloudWithPrefix()
    let emptyPrefix = CloudEmptyPrefix()

    noParams.cloudValue1 = "test1"
    withPrefix.cloudValue2 = "test2"
    emptyPrefix.cloudValue3 = "test3"

    #expect(noParams.cloudValue1 == "test1")
    #expect(withPrefix.cloudValue2 == "test2")
    #expect(emptyPrefix.cloudValue3 == "test3")
}

@Test(.testMode)
func defaultsParameterTests() {
    let noParams = DefaultsNoParams()
    let withPrefix = DefaultsWithPrefix()
    let withSuite = DefaultsWithSuite()
    let withBoth = DefaultsWithBoth()
    let emptyParams = DefaultsEmptyParams()

    noParams.defaultsValue1 = "test1"
    withPrefix.defaultsValue2 = "test2"
    withSuite.defaultsValue3 = "test3"
    withBoth.defaultsValue4 = "test4"
    emptyParams.defaultsValue5 = "test5"

    #expect(noParams.defaultsValue1 == "test1")
    #expect(withPrefix.defaultsValue2 == "test2")
    #expect(withSuite.defaultsValue3 == "test3")
    #expect(withBoth.defaultsValue4 == "test4")
    #expect(emptyParams.defaultsValue5 == "test5")
}
