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
/// - Important: `willSet` and `didSet` are not supported on `@DefaultsBacked` properties
@attached(peer, names: prefixed(`_`), arbitrary)
@attached(accessor, names: named(get), named(set))
public macro DefaultsBacked(userDefaultsKey: String? = nil) =
    #externalMacro(
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
public macro DefaultsKey(userDefaultsKey: String? = nil) =
    #externalMacro(
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
/// - Important: `willSet` and `didSet` are supported on `@ObservableOnly` properties,
///   including properties automatically marked in Observe First mode
@attached(peer, names: prefixed(`_`))
@attached(accessor, names: named(get), named(set), named(init), named(_modify))
public macro ObservableOnly() =
    #externalMacro(
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
///     observeFirst: false,
///     limitToInstance: true
/// )
/// class Settings {
///     // Properties automatically managed
/// }
/// ```
///
/// Cross-process synchronization (App Groups):
/// ```swift
/// @ObservableDefaults(
///     suiteName: "group.myapp",
///     prefix: "widget_",  // Use unique prefix to avoid key conflicts
///     limitToInstance: false  // Enable cross-process notifications
/// )
/// class WidgetSettings {
///     var sharedData: String = "shared"  // Syncs across app and widgets
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
/// - `limitToInstance`: Limits observations to the specific UserDefaults instance. Set to false for App Group cross-process synchronization (default: true)
/// - `defaultIsolationIsMainActor`: Set to true when project's defaultIsolation is MainActor (default: false)
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
/// - Note: Supports Codable types
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
    named(shouldSetValue),
    named(observerStarter),
    named(_defaultsKeyPathMap),
    named(_ignoredKeyPathsForExternalUpdates))
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro ObservableDefaults(
    autoInit: Bool = true,
    ignoreExternalChanges: Bool = false,
    suiteName: String = "",
    prefix: String = "",
    observeFirst: Bool = false,
    limitToInstance: Bool = true,
    defaultIsolationIsMainActor: Bool = false
) =
    #externalMacro(
        module: "ObservableDefaultsMacros",
        type: "ObservableDefaultsMacros")

/// A macro that provides automatic NSUbiquitousKeyValueStore (iCloud Key-Value Storage) integration
/// for individual properties within classes marked with `@ObservableCloud`.
///
/// The `@CloudBacked` macro generates getter and setter accessors that automatically:
/// - Store and retrieve values from NSUbiquitousKeyValueStore for cross-device synchronization
/// - Support development mode for testing without CloudKit container requirements
/// - Integrate seamlessly with SwiftUI's Observation framework for precise view updates
/// - Handle immediate synchronization when configured
/// - Provide automatic fallback to default values when cloud data is unavailable
///
/// ## Basic Usage
///
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     @CloudBacked
///     var username: String = "Fatbobman"  // Automatically synced to iCloud
///
///     @CloudBacked
///     var theme: Theme = .light           // Enum support
///
///     @CloudBacked
///     var preferences: UserPrefs = UserPrefs()  // Custom Codable types
/// }
/// ```
///
/// ## Custom Key Specification
///
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     @CloudBacked(keyValueStoreKey: "user_display_name")
///     var username: String = "Fatbobman"
///
///     // Alternative syntax using @CloudKey
///     @CloudKey(keyValueStoreKey: "app_theme_setting")
///     @CloudBacked
///     var theme: Theme = .light
/// }
/// ```
///
/// ## Requirements
///
/// - Must be used within a class marked with `@ObservableCloud`
/// - Property must have a default value (initializer required)
/// - Property type must not be optional
/// - Property must not already have custom accessors
/// - Property type must conform to appropriate storage protocols
/// - `willSet` and `didSet` are not supported on `@CloudBacked` properties
///
/// ## Generated Code
///
/// The macro generates:
/// - A private storage property with underscore prefix (`_propertyName`)
/// - Custom getter that reads from cloud storage or memory (development mode)
/// - Custom setter that writes to cloud storage with observation support
///
/// ## Development Mode
///
/// In development mode, properties use memory storage instead of NSUbiquitousKeyValueStore,
/// enabling testing without CloudKit setup. Development mode is automatically enabled when:
/// - Explicitly set via `@ObservableCloud(developmentMode: true)`
/// - Running in SwiftUI Previews
/// - `OBSERVABLE_DEFAULTS_DEV_MODE` environment variable is set
///
/// - Important: NSUbiquitousKeyValueStore has a 1MB total storage limit and 1024 key limit
/// - Note: Changes are automatically observed across devices via NotificationCenter integration
/// - Warning: Changing property names or custom keys after deployment may cause data loss
@attached(peer, names: prefixed(`_`), arbitrary)
@attached(accessor, names: named(get), named(set))
public macro CloudBacked(keyValueStoreKey: String? = nil) =
    #externalMacro(
        module: "ObservableDefaultsMacros",
        type: "CloudBackedMacro")

/// A marker macro that provides an alternative syntax for specifying custom
/// NSUbiquitousKeyValueStore
/// keys for properties used with `@CloudBacked`.
///
/// The `@CloudKey` macro is a metadata-only macro that doesn't generate code itself.
/// Instead, it provides a cleaner, more explicit way to specify custom cloud storage keys
/// that are read by the `@CloudBacked` macro during code generation.
///
/// ## Usage
///
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     // Using @CloudKey for better readability
///     @CloudKey(keyValueStoreKey: "user_display_name")
///     @CloudBacked
///     var username: String = "Fatbobman"
///
///     // Equivalent to using @CloudBacked parameter
///     @CloudBacked(keyValueStoreKey: "user_display_name")
///     var username: String = "Fatbobman"
/// }
/// ```
///
/// ## Key Resolution Priority
///
/// When both `@CloudKey` and `@CloudBacked(keyValueStoreKey:)` are present:
/// 1. `@CloudBacked(keyValueStoreKey:)` parameter (highest priority)
/// 2. `@CloudKey(keyValueStoreKey:)` parameter
/// 3. Property name (default fallback)
///
/// ## Best Practices
///
/// - Use descriptive, stable names that won't change across app versions
/// - Avoid special characters that might cause key-value storage issues
/// - Consider using consistent naming patterns (snake_case or camelCase)
/// - Prefix keys to avoid conflicts with system or framework keys
///
/// ## Advantages
///
/// - **Separation of Concerns**: Keeps key specification separate from storage behavior
/// - **Readability**: Makes custom key usage more explicit and visible
/// - **Flexibility**: Allows for future extensions without changing `@CloudBacked` syntax
/// - **Consistency**: Provides uniform key specification across different storage macros
///
/// - Note: This is a marker macro - no code generation occurs
/// - Important: Must be used with `@CloudBacked` to have any effect
/// - Warning: Changing keys after deployment will make existing cloud data inaccessible
@attached(peer)
public macro CloudKey(keyValueStoreKey: String? = nil) =
    #externalMacro(
        module: "ObservableDefaultsMacros",
        type: "CloudKeyMacro")

/// A comprehensive macro that automatically integrates NSUbiquitousKeyValueStore with SwiftUI's
/// Observation framework for seamless cloud data synchronization.
///
/// The `@ObservableCloud` macro transforms a class into a fully observable cloud-backed data store
/// by:
/// - Making the class conform to the `Observable` protocol for SwiftUI integration
/// - Automatically managing NSUbiquitousKeyValueStore synchronization for marked properties
/// - Handling external cloud store changes via NotificationCenter observation
/// - Providing precise view updates in SwiftUI applications
/// - Supporting development mode for testing without CloudKit container requirements
///
/// ## Basic Usage
///
/// ```swift
/// @ObservableCloud
/// class CloudSettings {
///     var username: String = "Fatbobman"  // Automatically cloud-backed
///     var theme: String = "light"         // Automatically cloud-backed
///     var isFirstLaunch: Bool = true      // Automatically cloud-backed
/// }
///
/// // Usage in SwiftUI
/// struct ContentView: View {
///     @State private var settings = CloudSettings()
///
///     var body: some View {
///         VStack {
///             Text("Hello, \(settings.username)!")  // Automatically updates
///             Button("Toggle Theme") {
///                 settings.theme = settings.theme == "light" ? "dark" : "light"
///             }
///         }
///     }
/// }
/// ```
///
/// ## Configuration Options
///
/// ```swift
/// @ObservableCloud(
///     autoInit: true,              // Generate automatic initializer
///     prefix: "myApp_",            // Prefix for all cloud keys
///     observeFirst: false,         // Enable Observe First mode
///     syncImmediately: true,       // Force immediate synchronization
///     developmentMode: false       // Use memory storage for testing
/// )
/// class CloudSettings {
///     // Properties automatically managed based on configuration
/// }
/// ```
///
/// ## Observe First Mode
///
/// When `observeFirst: true`, properties are observable but not automatically cloud-backed:
///
/// ```swift
/// @ObservableCloud(observeFirst: true)
/// class CloudSettings {
///     var localSetting: String = "local"     // Observable only (not stored)
///
///     @CloudBacked
///     var cloudSetting: String = "cloud"     // Observable and cloud-backed
/// }
/// ```
///
/// ## Development Mode
///
/// For testing and development without CloudKit setup:
///
/// ```swift
/// @ObservableCloud(developmentMode: true)
/// class CloudSettings {
///     // All properties use memory storage instead of NSUbiquitousKeyValueStore
///     var setting1: String = "value1"
///     var setting2: Int = 42
/// }
/// ```
///
/// Development mode is automatically enabled when:
/// - Explicitly set via `developmentMode: true`
/// - Running in SwiftUI Previews (`XCODE_RUNNING_FOR_PREVIEWS` environment variable)
/// - `OBSERVABLE_DEFAULTS_DEV_MODE` environment variable is set to "true"
///
/// ## Generated Members
///
/// The macro automatically generates:
/// - **Observation Infrastructure**: `_$observationRegistrar`, `access()`, `withMutation()`
/// - **Configuration Properties**: `_prefix`, `_syncImmediately`, `_developmentMode`
/// - **Cloud Observation**: `CloudObservation` class for external change handling
/// - **Optional Initializer**: When `autoInit: true` (default)
///
/// ## Synchronization Behavior
///
/// - **Immediate Sync**: When `syncImmediately: true`, calls `synchronize()` after each write
/// - **Deferred Sync**: When `false`, relies on system's automatic synchronization
/// - **External Changes**: Automatically observes changes from other devices
/// - **Conflict Resolution**: Uses NSUbiquitousKeyValueStore's last-writer-wins strategy
///
/// ## Key Management
///
/// - **Automatic Keys**: Property names are used as NSUbiquitousKeyValueStore keys by default
/// - **Custom Keys**: Use `@CloudBacked(keyValueStoreKey:)` or `@CloudKey` for custom keys
/// - **Prefix Support**: Global prefix applied to all keys to avoid conflicts
/// - **Key Validation**: Prefix must not contain '.' characters to avoid KVO issues
///
/// ## Performance Considerations
///
/// - **Lazy Loading**: Cloud values are loaded on first access
/// - **Caching**: Default values are cached in private storage properties
/// - **Precise Updates**: SwiftUI views update only when observed properties change
/// - **Background Sync**: External changes are processed on background queues
///
/// ## Error Handling and Limitations
///
/// - **Storage Limits**: NSUbiquitousKeyValueStore has 1MB total and 1024 key limits
/// - **Network Dependency**: Requires iCloud account and network connectivity
/// - **Type Restrictions**: Only supports CloudPropertyListValue-compatible types
/// - **Class Only**: Can only be applied to classes, not structs
/// - **Automatic Fallback**: Uses default values when cloud data is unavailable
///
/// ## Integration with Other Macros
///
/// - **@CloudBacked**: Explicitly marks properties for cloud storage
/// - **@CloudKey**: Provides custom key specification
/// - **@ObservableOnly**: In Observe First mode, marks properties as observable-only
///
/// - Important: Can only be applied to classes, not structs
/// - Note: Supports all CloudPropertyListValue types and Codable types
/// - Warning: Changing class structure after deployment may affect cloud data compatibility
@attached(
    member,
    names: named(_$observationRegistrar),
    named(access),
    named(withMutation),
    named(getValue),
    named(setValue),
    named(init),
    named(_prefix),
    named(shouldSetValue),
    named(_observableCloudLogger),
    named(_cloudObserver),
    named(CloudObservation),
    named(_syncImmediately),
    named(_developmentMode_),
    named(_developmentMode))
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro ObservableCloud(
    autoInit: Bool = true,
    prefix: String = "",
    observeFirst: Bool = false,
    syncImmediately: Bool = false,
    developmentMode: Bool = false,
    defaultIsolationIsMainActor: Bool = false
) =
    #externalMacro(
        module: "ObservableDefaultsMacros",
        type: "ObservableCloudMacros")
