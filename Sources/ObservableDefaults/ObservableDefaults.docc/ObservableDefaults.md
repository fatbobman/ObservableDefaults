# ``ObservableDefaults``

A Swift library that seamlessly integrates UserDefaults with SwiftUI's Observation framework.

## Overview

ObservableDefaults simplifies UserDefaults management in SwiftUI applications by providing a macro-based solution that automatically synchronizes properties with UserDefaults while integrating with the Observation framework for precise view updates.

### Key Features

- **Seamless Integration**: Works directly with SwiftUI's Observation framework introduced in iOS 17
- **Automatic Synchronization**: Properties are automatically backed by UserDefaults storage
- **Precise Updates**: Only affected views update when specific properties change
- **External Change Handling**: Responds to UserDefaults modifications from outside your app
- **Flexible Configuration**: Support for custom keys, prefixes, and UserDefaults suites
- **Type Safety**: Compile-time validation for supported property types

## Basic Usage

The simplest way to use ObservableDefaults is to mark your class with the `@ObservableDefaults` macro:

```swift
import ObservableDefaults

@ObservableDefaults
class AppSettings {
    var username: String = "Guest"
    var fontSize: Double = 16.0
    var isDarkMode: Bool = false
    var lastLoginDate: Date = Date()
}
```

Use the settings class in your SwiftUI views:

```swift
struct ContentView: View {
    @State private var settings = AppSettings()
    
    var body: some View {
        VStack {
            Text("Hello, \(settings.username)!")
                .font(.system(size: settings.fontSize))
            
            Toggle("Dark Mode", isOn: $settings.isDarkMode)
            
            Slider(value: $settings.fontSize, in: 12...24)
        }
    }
}
```

## Advanced Configuration

### Custom UserDefaults Keys

Use `@DefaultsKey` to specify custom UserDefaults keys:

```swift
@ObservableDefaults
class UserPreferences {
    @DefaultsKey(userDefaultsKey: "user_name")
    var displayName: String = "Anonymous"
    
    @DefaultsKey(userDefaultsKey: "app_theme")
    var theme: String = "system"
}
```

### Key Prefixes

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

### Custom UserDefaults Suite

Use a shared UserDefaults suite for app groups:

```swift
@ObservableDefaults(suiteName: "group.com.yourcompany.yourapp")
class SharedSettings {
    var sharedCounter: Int = 0
    var sharedMessage: String = "Hello from extension!"
}
```

## Operation Modes

### Standard Mode (Default)

In standard mode, all properties are automatically stored in UserDefaults:

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

```swift
@ObservableDefaults(observeFirst: true)
class ObserveFirstSettings {
    var displayName: String = "User"    // Only observable (not stored)
    var sessionId: String = ""          // Only observable (not stored)
    
    @DefaultsBacked
    var savedUsername: String = "john"  // Observable and stored
    
    @Ignore
    var tempData: String = ""           // Neither observable nor stored
}
```

## Handling External Changes

ObservableDefaults automatically responds to UserDefaults changes made outside your app:

```swift
@ObservableDefaults(ignoreExternalChanges: false) // Default behavior
class SyncedSettings {
    var syncedValue: String = "initial"
}

// When another process modifies UserDefaults, your SwiftUI views automatically update
```

To ignore external changes:

```swift
@ObservableDefaults(ignoreExternalChanges: true)
class IsolatedSettings {
    var localValue: String = "local"
}
```

## Supported Types

ObservableDefaults supports all types that conform to `UserDefaultsPropertyListValue`:

### Basic Types

- `String`, `Int`, `Double`, `Float`, `Bool`
- `Date`, `Data`, `URL`
- All integer types (`Int8`, `Int16`, `Int32`, `Int64`, `UInt`, etc.)

### Collection Types

- `Array<Element>` where `Element: UserDefaultsPropertyListValue`
- `Dictionary<String, Value>` where `Value: UserDefaultsPropertyListValue`

### Custom Types

For custom types, implement `CodableUserDefaultsPropertyListValue`:

```swift
struct UserProfile: CodableUserDefaultsPropertyListValue {
    let name: String
    let email: String
    let preferences: [String: String]
}

@ObservableDefaults
class ProfileSettings {
    var currentProfile: UserProfile = UserProfile(
        name: "Guest",
        email: "",
        preferences: [:]
    )
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

## Initialization Options

When `autoInit` is enabled (default), ObservableDefaults generates a flexible initializer:

```swift
@ObservableDefaults
class ConfigurableSettings {
    var value: String = "default"
}

// Usage with different configurations
let settings1 = ConfigurableSettings()

let settings2 = ConfigurableSettings(
    userDefaults: UserDefaults(suiteName: "custom.suite"),
    ignoreExternalChanges: true,
    prefix: "Debug_"
)

let settings3 = ConfigurableSettings(
    ignoredKeyPathsForExternalUpdates: [\.value]
)
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
