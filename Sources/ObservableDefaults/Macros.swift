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

/// A macro that generates UserDefaults-backed storage and observation for properties.
///
/// This macro automatically:
/// - Creates getter/setter accessors that read from and write to UserDefaults
/// - Integrates with SwiftUI's Observation framework for precise view updates
/// - Generates a private storage property for the default value
/// - Supports custom UserDefaults keys via the optional parameter
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Automatically gets @DefaultsBacked
///
///     @DefaultsBacked(userDefaultsKey: "firstName")
///     var customName: String = "John"  // Uses custom key "firstName"
/// }
/// ```
///
/// - Note: Properties must have default values and cannot be optional types
@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro DefaultsBacked(userDefaultsKey: String? = nil) = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "DefaultsBackedMacro")

/// A macro that specifies a custom UserDefaults key for a property.
///
/// By default, ObservableDefaults uses the property name as the UserDefaults key.
/// This macro allows you to override that behavior with a custom key name.
/// When a prefix is set at the class level, the final key becomes: prefix + custom_key
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     @DefaultsKey(userDefaultsKey: "firstName")
///     var name: String = "John"  // Stored with key "firstName" instead of "name"
/// }
/// ```
///
/// With prefix:
/// ```swift
/// @ObservableDefaults(prefix: "myApp_")
/// class Settings {
///     @DefaultsKey(userDefaultsKey: "firstName")
///     var name: String = "John"  // Final key: "myApp_firstName"
/// }
/// ```
///
/// - Note: This is a marker macro that provides metadata for other macros
@attached(peer)
public macro DefaultsKey(userDefaultsKey: String? = nil) = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "DefaultsKeyMacro")

/// A macro that marks a property as neither observable nor stored in UserDefaults.
///
/// Properties marked with this macro are excluded from both SwiftUI observation
/// and UserDefaults synchronization, treating them as regular class properties.
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Observable and stored in UserDefaults
///
///     @Ignore
///     var weight: Int = 70  // Neither observable nor stored
/// }
/// ```
///
/// - Important: These properties will not trigger SwiftUI view updates
///   and will not persist between app launches
@attached(peer)
public macro Ignore() = #externalMacro(module: "ObservableDefaultsMacros", type: "IgnoreMacro")

/// A macro that marks a property as observable but not stored in UserDefaults.
///
/// This macro creates properties that can trigger SwiftUI view updates but don't
/// persist their values. It's particularly useful in Observe First mode where
/// it's automatically applied to properties that don't need persistence.
///
/// Usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Stored in UserDefaults
///
///     @ObservableOnly
///     var height: Int = 190  // Observable but not stored
/// }
/// ```
///
/// In Observe First mode:
/// ```swift
/// @ObservableDefaults(observeFirst: true)
/// class Settings {
///     var name: String = "fat"  // Automatically gets @ObservableOnly
///
///     @DefaultsBacked
///     var age: Int = 109  // Observable and stored
/// }
/// ```
///
/// - Note: Values will not persist between app launches
@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro ObservableOnly() = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "ObservableOnlyMacro")

/// A macro that creates an Observable class with automatic UserDefaults integration.
///
/// This macro generates the necessary code to:
/// - Make the class conform to the Observable protocol
/// - Automatically synchronize properties with UserDefaults
/// - Handle external UserDefaults changes via KVO observation
/// - Provide precise SwiftUI view updates
/// - Generate configuration properties and optional initializer
///
/// Basic usage:
/// ```swift
/// @ObservableDefaults
/// class Settings {
///     var name: String = "Fatbobman"  // Automatically stored in UserDefaults
///     var age: Int = 20              // Automatically stored in UserDefaults
/// }
/// ```
///
/// With configuration:
/// ```swift
/// @ObservableDefaults(
///     autoInit: true,
///     ignoreExternalChanges: false,
///     suiteName: "group.myapp",
///     prefix: "myApp_",
///     observeFirst: false
/// )
/// class Settings {
///     // Properties automatically managed
/// }
/// ```
///
/// Observe First mode (prioritizes observation over persistence):
/// ```swift
/// @ObservableDefaults(observeFirst: true)
/// class Settings {
///     var name: String = "fat"          // Only observable (not stored)
///
///     @DefaultsBacked
///     var age: Int = 109               // Observable and stored in UserDefaults
/// }
/// ```
///
/// Parameters:
/// - `autoInit`: Automatically generates an initializer (default: true)
/// - `ignoreExternalChanges`: Ignores external UserDefaults modifications (default: false)
/// - `suiteName`: Custom UserDefaults suite name (default: nil, uses standard)
/// - `prefix`: Prefix for all UserDefaults keys (default: nil, must not contain '.')
/// - `observeFirst`: Enables Observe First mode (default: false)
///
/// Generated initializer (when autoInit is true):
/// ```swift
/// public init(
///     userDefaults: UserDefaults? = nil,
///     ignoreExternalChanges: Bool? = nil,
///     prefix: String? = nil,
///     ignoredKeyPathsForExternalUpdates: [PartialKeyPath<ClassName>] = []
/// )
/// ```
///
/// - Important: Can only be applied to classes, not structs
/// - Note: Supports Codable types via CodableUserDefaultsPropertyListValue protocol
@attached(
    member,
    names: named(_$observationRegistrar),
    named(_userDefaults),
    named(_isExternalNotificationDisabled),
    named(access),
    named(withMutation),
    named(getValue),
    named(setValue),
    named(UserDefaultsWrapper),
    named(init),
    named(_prefix),
    named(cancellables),
    named(setupUserDefaultsObservation),
    named(checkForChanges),
    named(observer),
    named(DefaultsObservation),
    named(observerStarter),
    named(_defaultsKeyPathMap),
    named(_ignoredKeyPathsForExternalUpdates))
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro ObservableDefaults(
    autoInit: Bool = true,
    ignoreExternalChanges: Bool = false,
    suiteName: String? = nil,
    prefix: String? = nil,
    observeFirst: Bool = false) = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "ObservableDefaultsMacros")

@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro CloudBacked(keyValueStoreKey: String? = nil) = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "CloudBackedMacro")

@attached(peer)
public macro CloudKey(keyValueStoreKey: String? = nil) = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "CloudKeyMacro")

@attached(
    member,
    names: named(_$observationRegistrar),
    named(access),
    named(withMutation),
    named(getValue),
    named(setValue),
    named(init),
    named(_prefix),
    named(_cloudObserver),
    named(CloudObservation),
    named(_syncImmediately),
    named(developmentMode),
    named(_developmentMode))
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro ObservableCloud(
    autoInit: Bool = true,
    prefix: String? = nil,
    observeFirst: Bool = false,
    syncImmediately: Bool = false,
    developmentMode: Bool = false) = #externalMacro(
    module: "ObservableDefaultsMacros",
    type: "ObservableCloudMacros")
