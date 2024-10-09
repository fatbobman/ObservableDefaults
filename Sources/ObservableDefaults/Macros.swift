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

// A macro generated by ObservableDefaults to add UserDefaults-related logic to properties
@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro DefaultsBacked() = #externalMacro(module: "ObservableDefaultsMacros", type: "DefaultsBackedMacro")

// A macro to set the key name for a property in UserDefaults
// By default, ObservableDefaults uses the property name as the key
// If a custom key is set using DefaultsKey, it will be used instead
// When a prefix is set, the key becomes prefix + (custom key or property name)
@attached(peer)
public macro DefaultsKey(userDefaultsKey: String? = nil) = #externalMacro(module: "ObservableDefaultsMacros", type: "DefaultsKeyMacro")

// A macro to mark a property as non-observable and not associated with any UserDefaults key
@attached(peer)
public macro Ignore() = #externalMacro(module: "ObservableDefaultsMacros", type: "IgnoreMacro")

// A macro to mark a property as Observable but not associated with any UserDefaults key
@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro ObservableOnly() = #externalMacro(module: "ObservableDefaultsMacros", type: "ObservableOnlyMacro")

// A macro to create an Observable instance that responds to UserDefaults
// Data reading and writing will automatically correspond to keys in UserDefaults
// Parameters:
// - autoInit: Automatically build the initializer and respond to external UserDefaults changes when ignoreExternalChanges is false
// - ignoreExternalChanges: Ignore notifications from external modifications. When true, the instance will only respond to its own data modifications
// - suiteName: The suite name for UserDefaults
// - prefix: Prefix for UserDefaults keys. Note: It cannot contain the '.' character
// If a parameter is set in both the macro and the initializer, the value in the initializer takes precedence
@attached(member, names: named(_$observationRegistrar), named(_userDefaults), named(_isExternalNotificationDisabled), named(access), named(withMutation), named(getValue), named(setValue), named(UserDefaultsWrapper), named(init), named(_prefix), named(cancellables), named(setupUserDefaultsObservation),
          named(checkForChanges), named(observer), named(DefaultsObservation))
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro ObservableDefaults(autoInit: Bool = true, ignoreExternalChanges: Bool = false, suiteName: String? = nil, prefix: String? = nil) = #externalMacro(module: "ObservableDefaultsMacros", type: "ObservableDefaultsMacros")
