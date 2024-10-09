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

@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro DefaultsBacked() = #externalMacro(module: "ObservableDefaultsMacros", type: "DefaultsBackedMacro")

@attached(peer)
public macro DefaultsKey(userDefaultsKey: String? = nil) = #externalMacro(module: "ObservableDefaultsMacros", type: "DefaultsKeyMacro")

@attached(peer)
public macro GeneratedClassName(_ name: String) = #externalMacro(module: "ObservableDefaultsMacros", type: "GeneratedClassNameMacro")

@attached(peer)
public macro Ignore() = #externalMacro(module: "ObservableDefaultsMacros", type: "IgnoreMacro")

@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro ObservableOnly() = #externalMacro(module: "ObservableDefaultsMacros", type: "ObservableOnlyMacro")

@attached(member, names: named(_$observationRegistrar), named(_userDefaults), named(_isExternalNotificationDisabled), named(access), named(withMutation), named(getValue), named(setValue), named(UserDefaultsWrapper), named(init), named(_prefix), named(cancellables),named(setupUserDefaultsObservation),
          named(checkForChanges),named(observer),named(DefaultsObservation)
)
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro ObservableDefaults(autoInit: Bool = true, ignoreExternalChanges: Bool = false, suiteName: String? = nil, prefix: String? = nil) = #externalMacro(module: "ObservableDefaultsMacros", type: "ObservableDefaultsMacros")
