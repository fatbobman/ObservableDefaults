# ``ObservableDefaults``

A comprehensive Swift library that seamlessly integrates both UserDefaults and iCloud Key-Value Store with SwiftUI's Observation framework.

## Overview

`ObservableDefaults` is a comprehensive Swift library that seamlessly integrates both **`UserDefaults`** and **`NSUbiquitousKeyValueStore`** (iCloud Key-Value Storage) with SwiftUI's Observation framework. It provides two powerful macros - `@ObservableDefaults` for local UserDefaults management and `@ObservableCloud` for cloud-synchronized data storage - that simplify data persistence by automatically associating declared properties with their respective storage systems.

This enables precise and efficient responsiveness to data changes, whether they originate from within the app, externally, or across multiple devices.

### Key Features

- **Dual Storage Support**: Seamless integration with both `UserDefaults` and `NSUbiquitousKeyValueStore` (iCloud)
- **SwiftUI Observation**: Full integration with the SwiftUI Observation framework
- **Automatic Synchronization**: Properties automatically sync with their respective storage systems
- **Cross-Device Sync**: Cloud-backed properties automatically synchronize across user's devices
- **Precise Notifications**: Property-level change notifications, reducing unnecessary view updates
- **Development Mode**: Testing support without CloudKit container requirements
- **Customizable Behavior**: Fine-grained control through additional macros and parameters
- **Custom Keys and Prefixes**: Support for property-specific storage keys and global prefixes
- **Codable Support**: Complex data persistence for both local and cloud storage

## UserDefaults Integration with @ObservableDefaults

The simplest way to use ObservableDefaults is to mark your class with the `@ObservableDefaults` macro:

```swift
import ObservableDefaults

@ObservableDefaults
class Settings {
    var name: String = "Fatbobman"
    var age: Int = 20
}
```

This macro automatically:

- Associates the `name` and `age` properties with `UserDefaults` keys
- Listens for external changes to these keys and updates the properties accordingly
- Notifies SwiftUI views of changes precisely, avoiding unnecessary redraws

Use the settings class in your SwiftUI views:

```swift
struct ContentView: View {
    @State var settings = Settings()
    
    var body: some View {
        VStack {
            Text("Name: \(settings.name)")
            TextField("Enter name", text: $settings.name)
            
            Text("Age: \(settings.age)")
            Stepper("Age", value: $settings.age, in: 0...120)
        }
        .padding()
    }
}
```

## Cloud Storage Integration with @ObservableCloud

For cloud-synchronized data that automatically syncs across devices, use the `@ObservableCloud` macro:

```swift
import ObservableDefaults

@ObservableCloud
class CloudSettings {
    var username: String = "Fatbobman"
    var theme: String = "light"
    var isFirstLaunch: Bool = true
}
```

This macro automatically:

- Associates properties with `NSUbiquitousKeyValueStore` for iCloud synchronization
- Listens for external changes from other devices and updates properties accordingly
- Provides the same precise SwiftUI observation as `@ObservableDefaults`
- Supports development mode for testing without CloudKit container setup

Both `@ObservableDefaults` and `@ObservableCloud` classes work identically in SwiftUI views:

```swift
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

## Customizing Behavior with Additional Macros

### For @ObservableDefaults (UserDefaults)

The library provides additional macros for finer control:

- `@ObservableOnly`: The property is observable but not stored in `UserDefaults`
- `@Ignore`: The property is neither observable nor stored in `UserDefaults`
- `@DefaultsKey`: Specifies a custom `UserDefaults` key for the property
- `@DefaultsBacked`: The property is stored in `UserDefaults` and observable

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

### For @ObservableCloud (iCloud Storage)

Similar macro support with cloud-specific options:

- `@ObservableOnly`: The property is observable but not stored in `NSUbiquitousKeyValueStore`
- `@Ignore`: The property is neither observable nor stored
- `@CloudKey`: Specifies a custom `NSUbiquitousKeyValueStore` key for the property
- `@CloudBacked`: The property is stored in `NSUbiquitousKeyValueStore` and observable

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

## Advanced Configuration

### Custom Keys and Prefixes

Add a prefix to all UserDefaults keys:

```swift
@ObservableDefaults(prefix: "MyApp_")
class Settings {
    var apiEndpoint: String = "https://api.example.com"
    // Stored as "MyApp_apiEndpoint" in UserDefaults
    
    @DefaultsKey(userDefaultsKey: "server_url")
    var serverURL: String = "https://server.example.com"
    // Stored as "MyApp_server_url" in UserDefaults
}
```

### Macro Parameters

#### @ObservableDefaults Macro Parameters

You can set parameters directly in the `@ObservableDefaults` macro:

- `userDefaults`: The `UserDefaults` instance to use
- `ignoreExternalChanges`: Whether to ignore external changes
- `prefix`: A prefix for `UserDefaults` keys
- `autoInit`: Whether to automatically generate the initializer (default is `true`)
- `observeFirst`: Observation priority mode (default is `false`)

```swift
@ObservableDefaults(autoInit: false, ignoreExternalChanges: true, prefix: "myApp_")
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"
}
```

#### @ObservableCloud Macro Parameters

The cloud macro provides similar configuration options:

- `autoInit`: Whether to automatically generate the initializer (default is `true`)
- `prefix`: A prefix for `NSUbiquitousKeyValueStore` keys
- `observeFirst`: Observation priority mode (default is `false`)
- `syncImmediately`: Whether to force immediate synchronization (default is `false`)
- `developmentMode`: Whether to use memory storage for testing (default is `false`)

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

## Operation Modes

### Standard Mode (Default)

In standard mode, all properties are automatically stored in their respective storage systems:

```swift
@ObservableDefaults
class StandardSettings {
    var name: String = "John"        // Stored in UserDefaults
    var age: Int = 25               // Stored in UserDefaults
    
    @Ignore
    var temporaryValue: String = "" // Not stored, not observable
}
```

### Observe First Mode

In Observe First mode, properties are observable by default but not stored unless explicitly marked:

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

## Development Mode for Cloud Storage

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

## Supported Types

ObservableDefaults supports all types that conform to the respective property list value protocols:

### Basic Types

- `String`, `Int`, `Double`, `Float`, `Bool`
- `Date`, `Data`, `URL`
- All integer types (`Int8`, `Int16`, `Int32`, `Int64`, `UInt`, etc.)

### Collection Types

- `Array<Element>` where `Element` conforms to the property list value protocol
- `Dictionary<String, Value>` where `Value` conforms to the property list value protocol

### Custom Types

#### UserDefaults with Codable

For custom types with UserDefaults, implement `CodableUserDefaultsPropertyListValue`:

```swift
@ObservableDefaults
class LocalStore {
    var people: People = .init(name: "fat", age: 10)
}

struct People: CodableUserDefaultsPropertyListValue {
    var name: String
    var age: Int
}
```

#### Cloud Storage with Codable

For custom types with cloud storage, implement `CodableCloudPropertyListValue`:

```swift
@ObservableCloud
class CloudStore {
    var userProfile: UserProfile = .init(name: "fat", preferences: .init())
}

struct UserProfile: CodableCloudPropertyListValue {
    var name: String
    var preferences: UserPreferences
}

struct UserPreferences: Codable {
    var theme: String = "light"
    var fontSize: Int = 14
}
```

### Enum Support

Enums with raw values are automatically supported:

```swift
enum Theme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

@ObservableDefaults
class ThemeSettings {
    var selectedTheme: Theme = .system
}
```

### Initialization Options

When `autoInit` is enabled (default), ObservableDefaults generates flexible initializers:

#### @ObservableDefaults Parameters

```swift
public init(
    userDefaults: UserDefaults? = nil,
    ignoreExternalChanges: Bool? = nil,
    prefix: String? = nil
)
```

**Parameters:**

- `userDefaults`: The `UserDefaults` instance to use (default is `.standard`)
- `ignoreExternalChanges`: If `true`, the instance ignores external `UserDefaults` changes (default is `false`)
- `prefix`: A prefix for all `UserDefaults` keys associated with this class

#### @ObservableCloud Parameters

```swift
public init(
    prefix: String? = nil,
    syncImmediately: Bool = false,
    developmentMode: Bool = false
)
```

**Parameters:**

- `prefix`: A prefix for all `NSUbiquitousKeyValueStore` keys
- `syncImmediately`: If `true`, forces immediate synchronization after each change
- `developmentMode`: If `true`, uses memory storage instead of iCloud for testing

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

## Custom Initializer

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

## Integration Patterns

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

## Best Practices

### 1. Use Descriptive Property Names

```swift
@ObservableDefaults
class Settings {
    var isNotificationsEnabled: Bool = true  // Clear and descriptive
    var maxRetryAttempts: Int = 3            // Indicates purpose and type
}
```

### 2. Provide Sensible Defaults

```swift
@ObservableDefaults
class AppConfiguration {
    var cacheSize: Int = 100_000_000        // 100MB default
    var requestTimeout: TimeInterval = 30.0  // 30 seconds default
}
```

### 3. Group Related Settings

```swift
@ObservableDefaults(prefix: "UI_")
class UISettings {
    var fontSize: Double = 16.0
    var colorScheme: String = "system"
}

@ObservableDefaults(prefix: "Network_")
class NetworkSettings {
    var timeout: TimeInterval = 30.0
    var maxRetries: Int = 3
}
```

### 4. Use Observe First for Mixed Scenarios

```swift
@ObservableDefaults(observeFirst: true)
class MixedSettings {
    // Temporary UI state (not persisted)
    var currentTab: Int = 0
    var searchText: String = ""
    
    // Important settings (persisted)
    @DefaultsBacked
    var username: String = ""
    
    @DefaultsBacked
    var isFirstLaunch: Bool = true
}
```

## Important Notes

### General Notes

- **External Changes**: By default, both macros respond to external changes in their respective storage systems
- **Key Prefixes**: Use the `prefix` parameter to prevent key collisions when multiple classes use the same property names
- **Custom Keys**: Use `@DefaultsKey` or `@CloudKey` to specify custom keys for properties
- **Prefix Characters**: The prefix must not contain '.' characters

### Cloud-Specific Notes

- **iCloud Account**: Cloud storage requires an active iCloud account and network connectivity
- **Storage Limits**: `NSUbiquitousKeyValueStore` has a 1MB total storage limit and 1024 key limit
- **Synchronization**: Changes may take time to propagate across devices depending on network conditions
- **Development Mode**: Use development mode for testing without CloudKit container setup
- **Data Migration**: Changing property names or custom keys after deployment may cause cloud data to become inaccessible
- **Direct NSUbiquitousKeyValueStore Modifications**: Directly modifying values using `NSUbiquitousKeyValueStore.default.set()` will not trigger local property updates in ObservableCloud classes. This is due to NSUbiquitousKeyValueStore's communication mechanism, which does not send notifications for local modifications. Always modify properties through the ObservableCloud instance to ensure proper synchronization and view updates.
