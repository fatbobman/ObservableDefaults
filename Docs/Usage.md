# ObservableDefaults Usage Guide

English | [中文](Usage_zh.md)

### UserDefaults Integration with @ObservableDefaults

After importing `ObservableDefaults`, you can annotate your class with `@ObservableDefaults` to automatically manage `UserDefaults` synchronization:

```swift
import ObservableDefaults

@ObservableDefaults
class Settings {
    var name: String = "Fatbobman"
    var age: Int = 20
    var nickname: String? = nil  // Optional support
}
```

<https://github.com/user-attachments/assets/469d55e8-7468-44ac-b591-804c40815724>

This macro automatically:

- Associates the `name` and `age` properties with `UserDefaults` keys.
- Listens for external changes to these keys and updates the properties accordingly.
- Notifies SwiftUI views of changes precisely, avoiding unnecessary redraws.

### Cloud Storage Integration with @ObservableCloud

For cloud-synchronized data that automatically syncs across devices, use the `@ObservableCloud` macro:

```swift
import ObservableDefaults

@ObservableCloud
class CloudSettings {
    var number = 1
    var color: Colors = .red
    var style: FontStyle = .style1
    var cloudName: String? = nil  // Optional support
}
```

<https://github.com/user-attachments/assets/7e8dcf6b-3c8f-4bd3-8083-ff3c4a6bd6b0>

[Demo Code](https://gist.github.com/fatbobman/5ab86c35ac8cee93c8ac6ac4228a28a9)

This macro automatically:

- Associates properties with `NSUbiquitousKeyValueStore` for iCloud synchronization
- Listens for external changes from other devices and updates properties accordingly
- Provides the same precise SwiftUI observation as `@ObservableDefaults`
- Supports development mode for testing without CloudKit container setup

### Using in SwiftUI Views

Both `@ObservableDefaults` and `@ObservableCloud` classes work identically in SwiftUI views:

```swift
import SwiftUI

struct ContentView: View {
    @State var settings = Settings()        // UserDefaults-backed
    @State var cloudSettings = CloudSettings()  // iCloud-backed

    var body: some View {
        VStack {
            // Local settings
            Text("Name: \(settings.name)")
            TextField("Enter name", text: $settings.name)

            // Cloud-synchronized settings
            Text("Username: \(cloudSettings.username)")
            TextField("Enter username", text: $cloudSettings.username)
        }
        .padding()
    }
}
```

### Customizing Behavior with Additional Macros

#### For @ObservableDefaults (UserDefaults)

The library provides additional macros for finer control:

- `@ObservableOnly`: The property is observable but not stored in `UserDefaults`.
- `@Ignore`: The property is neither observable nor stored in `UserDefaults`.
- `@DefaultsKey`: Specifies a custom `UserDefaults` key for the property.
- `@DefaultsBacked`: The property is stored in `UserDefaults` and observable.
- `@DefaultsBacked` does not support `willSet` / `didSet`.

```swift
@ObservableDefaults
public class LocalSettings {
    @DefaultsKey(userDefaultsKey: "firstName")
    public var name: String = "fat"

    public var age = 109  // Automatically backed by UserDefaults

    @ObservableOnly
    public var height = 190  // Observable only, not persisted

    @Ignore
    public var weight = 10  // Neither observable nor persisted
}
```

#### For @ObservableCloud (iCloud Storage)

Similar macro support with cloud-specific options:

- `@ObservableOnly`: The property is observable but not stored in `NSUbiquitousKeyValueStore`.
- `@Ignore`: The property is neither observable nor stored.
- `@CloudKey`: Specifies a custom `NSUbiquitousKeyValueStore` key for the property.
- `@CloudBacked`: The property is stored in `NSUbiquitousKeyValueStore` and observable.
- `@CloudBacked` does not support `willSet` / `didSet`.

```swift
@ObservableCloud
public class CloudSettings {
    @CloudKey(keyValueStoreKey: "user_display_name")
    public var username: String = "Fatbobman"

    public var theme: String = "light"  // Automatically cloud-backed

    @ObservableOnly
    public var localCache: String = ""  // Observable only, not synced to cloud

    @Ignore
    public var temporaryData: String = ""  // Neither observable nor persisted
}
```

### Initializer and Parameters

#### @ObservableDefaults Parameters

With `autoInit: true`, the macro generates this initializer for the `Settings` class used above:

```swift
public init(
    userDefaults: Foundation.UserDefaults? = nil,
    ignoreExternalChanges: Bool? = nil,
    prefix: String? = nil,
    ignoredKeyPathsForExternalUpdates: [PartialKeyPath<Settings>] = []
)
```

**Parameters:**

- `userDefaults`: A per-instance store override. `nil` keeps the store selected by the macro's `suiteName`, or `.standard` when no suite is configured.
- `ignoreExternalChanges`: A per-instance override. `nil` preserves the enclosing macro's `ignoreExternalChanges` value.
- `prefix`: A per-instance key-prefix override. `nil` preserves the enclosing macro's `prefix` value.
- `ignoredKeyPathsForExternalUpdates`: Properties excluded from external storage update handling for this instance (default: none).

#### @ObservableCloud Parameters

With the default `@ObservableCloud` configuration, the macro generates:

```swift
public init(
    prefix: String? = nil,
    syncImmediately: Bool = false,
    developmentMode: Bool = false
)
```

**Parameters:**

- `prefix`: A per-instance key-prefix override. `nil` preserves the enclosing macro's `prefix` value.
- `syncImmediately`: Controls whether each write forces immediate synchronization.
- `developmentMode`: Selects memory-backed development storage instead of iCloud storage.

The generated default literals for `syncImmediately` and `developmentMode` match the values supplied to the enclosing macro. For example, `@ObservableCloud(syncImmediately: true)` generates `syncImmediately: Bool = true`; an explicit initializer argument still overrides that generated default.

#### Example Usage

```swift
// UserDefaults-backed settings
@State var settings = Settings(
    userDefaults: .standard,
    ignoreExternalChanges: false,
    prefix: "myApp_"
)

// Cloud-backed settings
@State var cloudSettings = CloudSettings(
    prefix: "myApp_",
    syncImmediately: true,
    developmentMode: false
)
```

### Macro Parameters

#### @ObservableDefaults Macro Parameters

You can set parameters directly in the `@ObservableDefaults` macro:

- `suiteName`: The `UserDefaults` suite name (default is empty, which uses `.standard`).
- `ignoreExternalChanges`: Whether to ignore external changes.
- `prefix`: A prefix for `UserDefaults` keys.
- `autoInit`: Whether to automatically generate the initializer (default is `true`).
- `observeFirst`: Observation priority mode (default is `false`).
- `limitToInstance`: Whether to limit observations to the specific UserDefaults instance (default is `true`). Set to `false` for App Group cross-process synchronization.
- `defaultIsolationIsMainActor`: Whether the target uses MainActor as its default isolation (default is `false`).

```swift
@ObservableDefaults(autoInit: false, ignoreExternalChanges: true, prefix: "myApp_")
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"
}

// For App Group cross-process synchronization
@ObservableDefaults(
    suiteName: "group.myapp",
    prefix: "myapp_",
    limitToInstance: false
)
class SharedSettings {
    var lastUpdate: Date = Date()
}
```

#### @ObservableCloud Macro Parameters

The cloud macro provides similar configuration options:

- `autoInit`: Whether to automatically generate the initializer (default is `true`).
- `prefix`: A prefix for `NSUbiquitousKeyValueStore` keys.
- `observeFirst`: Observation priority mode (default is `false`).
- `syncImmediately`: Whether to force immediate synchronization (default is `false`).
- `developmentMode`: Whether to use memory storage for testing (default is `false`).
- `defaultIsolationIsMainActor`: Whether the target uses MainActor as its default isolation (default is `false`).

```swift
@ObservableCloud(
    autoInit: true,
    prefix: "myApp_",
    observeFirst: false,
    syncImmediately: true,
    developmentMode: false
)
class CloudSettings {
    @CloudKey(keyValueStoreKey: "user_theme")
    var theme: String = "light"
}
```

### Development Mode for Cloud Storage

The `@ObservableCloud` macro supports development mode for testing without CloudKit setup:

```swift
@ObservableCloud(developmentMode: true)
class CloudSettings {
    var setting1: String = "value1"  // Uses memory storage
    var setting2: Int = 42           // Uses memory storage
}
```

Development mode is automatically enabled when:

- Explicitly set via `developmentMode: true`
- Running in SwiftUI Previews (`XCODE_RUNNING_FOR_PREVIEWS` environment variable)
- `OBSERVABLE_DEFAULTS_DEV_MODE` environment variable is set to "true"

### Custom Initializer

If you set `autoInit` to `false` for either macro, you need to create your own initializer:

```swift
// For @ObservableDefaults
init() {
    observerStarter()  // Start listening for UserDefaults changes
}

// For @ObservableCloud
init() {
    // Start Cloud Observation only in production mode
    if !_developmentMode_ {
        _cloudObserver = CloudObservation(host: self, prefix: _prefix)
    }
}
```

### Observe First Mode

Both macros support "Observe First" mode, where properties are observable by default but only explicitly marked properties are persisted:

#### UserDefaults Observe First Mode

```swift
@ObservableDefaults(observeFirst: true)
public class LocalSettings {
    public var name: String = "fat"        // Observable only
    public var age = 109                   // Observable only

    @DefaultsBacked(userDefaultsKey: "myHeight")
    public var height = 190                // Observable and persisted to UserDefaults

    @Ignore
    public var weight = 10                 // Neither observable nor persisted
}
```

#### Cloud Observe First Mode

```swift
@ObservableCloud(observeFirst: true)
public class CloudSettings {
    public var localSetting: String = "local"     // Observable only
    public var tempData = "temp"                  // Observable only

    @CloudBacked(keyValueStoreKey: "user_theme")
    public var theme: String = "light"            // Observable and synced to iCloud

    @Ignore
    public var cache = "cache"                    // Neither observable nor persisted
}
```

### Property Observers (`willSet` / `didSet`)

- `@DefaultsBacked` and `@CloudBacked` do not support `willSet` / `didSet`.
- `@ObservableOnly` supports `willSet` / `didSet`.
- In Observe First mode, properties automatically marked as `@ObservableOnly` also support `willSet` / `didSet`.

### Supporting Optional Types

Both macros fully support Optional properties:

```swift
@ObservableDefaults
class SettingsWithOptionals {
    var username: String? = nil
    var age: Int? = 25
    var isEnabled: Bool? = true

    @DefaultsKey(userDefaultsKey: "custom-optional-key")
    var customOptional: String? = nil
}

@ObservableCloud
class CloudSettingsWithOptionals {
    var cloudUsername: String? = nil
    var preferences: [String]? = nil

    @CloudKey(keyValueStoreKey: "user-settings")
    var userSettings: [String: String]? = nil
}
```

### Supporting Codable Types

Both macros support properties conforming to `Codable` for complex data persistence:

#### UserDefaults with Codable

```swift
@ObservableDefaults
class LocalStore {
    var people: People = .init(name: "fat", age: 10)
}

struct People: Codable {
    var name: String
    var age: Int
}
```

#### Cloud Storage with Codable

```swift
@ObservableCloud
class CloudStore {
    var userProfile: UserProfile = .init(name: "fat", preferences: .init())
}

struct UserProfile: Codable {
    var name: String
    var preferences: UserPreferences
}

struct UserPreferences: Codable {
    var theme: String = "light"
    var fontSize: Int = 14
}
```

### Enum RawRepresentable Types

Enums whose `RawValue` already conforms to the property-list set (for example `String`, `Int`, etc.) are persisted automatically via their raw value:

```swift
enum Theme: String {
    case light
    case dark
    case system
}

@ObservableDefaults
class AppearanceSettings {
    var theme: Theme = Theme.system
}
```

When a type conforms to both `RawRepresentable` and `Codable`, the library will prioritize the `RawRepresentable` storage method, storing values using their raw representation rather than JSON encoding. This ensures backward compatibility with existing data and provides more efficient storage for enum types.

### Storage Resolution Rules (Important for Direct Key Access)

These rules apply to both `@ObservableDefaults` (`UserDefaults`) and `@ObservableCloud` (`NSUbiquitousKeyValueStore`).
When a type matches multiple constraints, the implementation chooses the most specific path in this order:

1. `RawRepresentable & PropertyListValue & Codable`
2. `RawRepresentable & PropertyListValue`
3. `RawRepresentable` (where `RawValue` is a PropertyList-compatible type)
4. `PropertyListValue & Codable`
5. `PropertyListValue`
6. `Codable` only (JSON `Data` path; intentionally lower priority)

#### Persisted Format by Type Combination

- `RawRepresentable`-based paths: persist `rawValue`.
  - Example: `String`/`Int` raw values are stored directly as `String`/`Int`.
- `PropertyListValue` paths: persist the value directly as PropertyList-compatible objects.
- `Codable`-only path: persist JSON-encoded `Data`.
- `URL` / `NSURL` paths: persist JSON-encoded `Data` using `URL`'s Codable
  representation. They are not passed directly to `UserDefaults` or
  `NSUbiquitousKeyValueStore` as property-list objects.
- Optional values:
  - non-`nil`: stored using the same rules above
  - `nil`: key is removed

#### Read Fallback for Compatibility

For `RawRepresentable & PropertyListValue` (including `RawRepresentable & PropertyListValue & Codable`):

- Read attempts `rawValue` format first.
- If that fails, read falls back to direct `PropertyListValue` casting.

This fallback keeps older data readable when a property was previously persisted via direct PropertyList format and later evolved to a `RawRepresentable` type.

#### Consistency for Manual `UserDefaults` / Cloud Reads and Writes

If you also read/write these keys directly outside the macros, use the same format rules to avoid mismatches.

- Use `rawValue` for all `RawRepresentable`-based properties.
- Use direct PropertyList values for PropertyList paths.
- Use JSON `Data` only for `Codable`-only properties.
- Use JSON `Data` encoded from `URL` for `URL` / `NSURL` properties.
- Key naming follows macro key resolution:
  - default: `prefix + propertyName`
  - custom key: `@DefaultsKey` / `@CloudKey`

Example (`UserDefaults`):

```swift
// For RawRepresentable-backed property (rawValue: String)
defaults.set(theme.rawValue, forKey: "app_theme")

// For Codable-only property
defaults.set(try JSONEncoder().encode(profile), forKey: "app_profile")

// For URL / NSURL properties
defaults.set(try JSONEncoder().encode(homepageURL), forKey: "app_homepage")
```

### Integrating with Other Observable Objects

It's recommended to manage storage data separately from your main application state:

```swift
@Observable
class ViewState {
    var selection = 10
    var isLogin = false
    let localSettings = LocalSettings()    // UserDefaults-backed
    let cloudSettings = CloudSettings()    // iCloud-backed
}

struct ContentView: View {
    @State var state = ViewState()

    var body: some View {
        VStack(spacing: 30) {
            // Local settings
            Text("Local Name: \(state.localSettings.name)")
            Button("Modify Local Setting") {
                state.localSettings.name = "User \(Int.random(in: 0...1000))"
            }

            // Cloud settings
            Text("Cloud Username: \(state.cloudSettings.username)")
            Button("Modify Cloud Setting") {
                state.cloudSettings.username = "CloudUser \(Int.random(in: 0...1000))"
            }
        }
        .buttonStyle(.bordered)
    }
}
```
