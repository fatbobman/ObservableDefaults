//
//  WhitespaceTests.swift
//  Tests for whitespace handling in string parameters
//

import Foundation
import ObservableDefaults
import Testing

// Test whitespace handling in parameters

@ObservableCloud(prefix: "  abc  ", developmentMode: true)
class CloudWhitespacePrefix {
    var value = "default"
}

@ObservableCloud(prefix: "   ", developmentMode: true)
class CloudSpacesOnlyPrefix {
    var value = "default"
}

@ObservableCloud(prefix: "\n\t  \r", developmentMode: true)
class CloudNewlinesPrefix {
    var value = "default"
}

@ObservableDefaults(prefix: "  myapp_  ")
class DefaultsWhitespacePrefix {
    var value = "default"
}

@ObservableDefaults(suiteName: "  group.test  ")
class DefaultsWhitespaceSuite {
    var value = "default"
}

@ObservableDefaults(suiteName: "   ", prefix: "\t\t")
class DefaultsWhitespaceOnly {
    var value = "default"
}

@ObservableDefaults(suiteName: " group.app ", prefix: " prefix_ ")
class DefaultsBothWithWhitespace {
    var value = "default"
}

// Test unicode whitespace characters
@ObservableCloud(prefix: "\u{00A0}\u{2000}\u{2001}test\u{2002}\u{2003}", developmentMode: true)
class UnicodeWhitespace {
    var unicodeValue = "default"
}

// Test tabs and carriage returns
@ObservableDefaults(prefix: "\t\r\n  tab_prefix  \r\n\t")
class TabsAndReturns {
    var tabValue = "default"
}

@Test(.testMode)
func cloudWhitespaceHandling() {
    let whitespacePrefix = CloudWhitespacePrefix()
    let spacesOnly = CloudSpacesOnlyPrefix()
    let newlines = CloudNewlinesPrefix()

    whitespacePrefix.value = "test1"
    spacesOnly.value = "test2"
    newlines.value = "test3"

    #expect(whitespacePrefix.value == "test1")
    #expect(spacesOnly.value == "test2")
    #expect(newlines.value == "test3")
}

@Test(.testMode)
func defaultsWhitespaceHandling() {
    let whitespacePrefix = DefaultsWhitespacePrefix()
    let whitespaceSuite = DefaultsWhitespaceSuite()
    let whitespaceOnly = DefaultsWhitespaceOnly()
    let bothWhitespace = DefaultsBothWithWhitespace()

    whitespacePrefix.value = "test1"
    whitespaceSuite.value = "test2"
    whitespaceOnly.value = "test3"
    bothWhitespace.value = "test4"

    #expect(whitespacePrefix.value == "test1")
    #expect(whitespaceSuite.value == "test2")
    #expect(whitespaceOnly.value == "test3")
    #expect(bothWhitespace.value == "test4")
}

@Test(.testMode)
func extremeWhitespaceEdgeCases() {
    let unicode = UnicodeWhitespace()
    let tabs = TabsAndReturns()

    unicode.unicodeValue = "unicode_test"
    tabs.tabValue = "tabs_test"

    #expect(unicode.unicodeValue == "unicode_test")
    #expect(tabs.tabValue == "tabs_test")
}
