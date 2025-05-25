# ObservableDefaults

![Swift 6](https://img.shields.io/badge/Swift-6-orange?logo=swift) ![iOS](https://img.shields.io/badge/iOS-17.0+-green) ![macOS](https://img.shields.io/badge/macOS-14.0+-green) ![watchOS](https://img.shields.io/badge/watchOS-10.0+-green) ![visionOS](https://img.shields.io/badge/visionOS-1.0+-green) ![tvOS](https://img.shields.io/badge/tvOS-17.0+-green) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Seamless SwiftUI + Observation + UserDefaults + iCloud Key-Value Store integration

`ObservableDefaults` is a comprehensive Swift library that seamlessly integrates both **`UserDefaults`** and **`NSUbiquitousKeyValueStore`** (iCloud Key-Value Storage) with SwiftUI's Observation framework. It provides two powerful macros - `@ObservableDefaults` for local UserDefaults management and `@ObservableCloud` for cloud-synchronized data storage - that simplify data persistence by automatically associating declared properties with their respective storage systems. This enables precise and efficient responsiveness to data changes, whether they originate from within the app, externally, or across multiple devices.

## Motivation

Managing multiple UserDefaults keys and cloud-synchronized data in SwiftUI can lead to bloated code and increase the risk of errors. While @AppStorage simplifies handling single UserDefaults keys, it doesn't scale well for multiple keys, lacks cloud synchronization capabilities, or offer precise view updates. With the introduction of the Observation framework, there's a need for a comprehensive solution that efficiently bridges both local and cloud storage with SwiftUI's state management.

ObservableDefaults was created to address these challenges by providing a complete data persistence solution. It leverages macros to reduce boilerplate code and ensures that your SwiftUI views respond accurately to changes in both UserDefaults and iCloud data.

For an in-depth discussion on the limitations of @AppStorage and the motivation behind ObservableDefaults, you can read the full article on [my blog](https://fatbobman.com/en/posts/userdefaults-and-observation).

---

Don't miss out on the latest updates and excellent articles about Swift, SwiftUI, Core Data, and SwiftData. Subscribe to **[Fatbobman's Swift Weekly](https://weekly.fatbobman.com)** and receive weekly insights and valuable content directly to your inbox.

---

## Features

- **Dual Storage Support**: Seamless integration with both `UserDefaults` and `NSUbiquitousKeyValueStore` (iCloud)
- **SwiftUI Observation**: Full integration with the SwiftUI Observation framework
- **Automatic Synchronization**: Properties automatically sync with their respective storage systems
- **Cross-Device Sync**: Cloud-backed properties automatically synchronize across user's devices
- **Precise Notifications**: Property-level change notifications, reducing unnecessary view updates
- **Development Mode**: Testing support without CloudKit container requirements
- **Customizable Behavior**: Fine-grained control through additional macros and parameters
- **Custom Keys and Prefixes**: Support for property-specific storage keys and global prefixes
- **Codable Support**: Complex data persistence for both local and cloud storage

## Installation

You can add `ObservableDefaults` to your project using Swift Package Manager:

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL: `https://github.com/fatbobman/ObservableDefaults`
3. Select the package and add it to your project.

## Usage

### UserDefaults Integration with @ObservableDefaults

After importing `ObservableDefaults`, you can annotate your class with `@ObservableDefaults` to automatically manage `UserDefaults` synchronization:

```swift
import ObservableDefaults

@ObservableDefaults
class Settings {
    var name: String = "Fatbobman"
    var age: Int = 20
}
```

https://github.com/user-attachments/assets/469d55e8-7468-44ac-b591-804c40815724

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
}
```

https://github.com/user-attachments/assets/7e8dcf6b-3c8f-4bd3-8083-ff3c4a6bd6b0

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

If all properties have default values, you can use the automatically generated initializer:

```swift
public init(
    userDefaults: UserDefaults? = nil,
    ignoreExternalChanges: Bool? = nil,
    prefix: String? = nil
)
```

**Parameters:**

- `userDefaults`: The `UserDefaults` instance to use (default is `.standard`).
- `ignoreExternalChanges`: If `true`, the instance ignores external `UserDefaults` changes (default is `false`).
- `prefix`: A prefix for all `UserDefaults` keys associated with this class.

#### @ObservableCloud Parameters

The cloud version provides similar initialization options:

```swift
public init(
    prefix: String? = nil,
    syncImmediately: Bool = false,
    developmentMode: Bool = false
)
```

**Parameters:**

- `prefix`: A prefix for all `NSUbiquitousKeyValueStore` keys.
- `syncImmediately`: If `true`, forces immediate synchronization after each change.
- `developmentMode`: If `true`, uses memory storage instead of iCloud for testing.

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

- `userDefaults`: The `UserDefaults` instance to use.
- `ignoreExternalChanges`: Whether to ignore external changes.
- `prefix`: A prefix for `UserDefaults` keys.
- `autoInit`: Whether to automatically generate the initializer (default is `true`).
- `observeFirst`: Observation priority mode (default is `false`).

```swift
@ObservableDefaults(autoInit: false, ignoreExternalChanges: true, prefix: "myApp_")
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"
}
```

#### @ObservableCloud Macro Parameters

The cloud macro provides similar configuration options:

- `autoInit`: Whether to automatically generate the initializer (default is `true`).
- `prefix`: A prefix for `NSUbiquitousKeyValueStore` keys.
- `observeFirst`: Observation priority mode (default is `false`).
- `syncImmediately`: Whether to force immediate synchronization (default is `false`).
- `developmentMode`: Whether to use memory storage for testing (default is `false`).

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

### Supporting Codable Types

Both macros support properties conforming to `Codable` for complex data persistence:

#### UserDefaults with Codable

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

## Important Notes

### General Notes

- **External Changes**: By default, both macros respond to external changes in their respective storage systems.
- **Key Prefixes**: Use the `prefix` parameter to prevent key collisions when multiple classes use the same property names.
- **Custom Keys**: Use `@DefaultsKey` or `@CloudKey` to specify custom keys for properties.
- **Prefix Characters**: The prefix must not contain '.' characters.

### Cloud-Specific Notes

- **iCloud Account**: Cloud storage requires an active iCloud account and network connectivity.
- **Storage Limits**: `NSUbiquitousKeyValueStore` has a 1MB total storage limit and 1024 key limit.
- **Synchronization**: Changes may take time to propagate across devices depending on network conditions.
- **Development Mode**: Use development mode for testing without CloudKit container setup.
- **Data Migration**: Changing property names or custom keys after deployment may cause cloud data to become inaccessible.
- **Direct NSUbiquitousKeyValueStore Modifications**: Directly modifying values using `NSUbiquitousKeyValueStore.default.set()` will not trigger local property updates in ObservableCloud classes. This is due to NSUbiquitousKeyValueStore's communication mechanism, which does not send notifications for local modifications. Always modify properties through the ObservableCloud instance to ensure proper synchronization and view updates.

## License

`ObservableDefaults` is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

Special thanks to the Swift community for their continuous support and contributions.

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://buymeacoffee.com/fatbobman)
