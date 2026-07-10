# ObservableDefaults Behavior and Integration Notes

English | [中文](Behavior_zh.md)

### Using with SwiftUI #Preview

When using `@ObservableCloud` classes with SwiftUI's `#Preview` and `@Previewable`, you may encounter an error: "cannot be constructed because it has no accessible initializers". This is because `@Previewable` requires a parameter-less initializer. Here are two solutions:

#### Solution 1: Add a Convenience Initializer

```swift
@ObservableCloud
class CloudSettings {
    var item: Bool = true

    // Add this convenience initializer for Preview support
    convenience init() {
        self.init(prefix: nil, syncImmediately: false, developmentMode: true)
    }
}

#Preview {
    @Previewable var settings = CloudSettings()
    ContentView()
        .environment(settings)
}
```

Note: Setting `developmentMode: true` in the convenience initializer ensures the Preview uses memory storage instead of requiring CloudKit, which is ideal for Preview environments.

#### Solution 2: Use a Singleton Pattern

```swift
@ObservableCloud
class CloudSettings {
    var item: Bool = true

    static let shared = CloudSettings()
}

#Preview {
    @Previewable var settings = CloudSettings.shared
    ContentView()
        .environment(settings)
}
```

### CI/CD Configuration

When using ObservableDefaults in CI/CD environments, you may need to add the `-skipMacroValidation` flag to your build commands to avoid macro validation issues:

```bash
# For Swift CLI
swift build -Xswiftc -skipMacroValidation
swift test -Xswiftc -skipMacroValidation

# For xcodebuild
xcodebuild build OTHER_SWIFT_FLAGS="-skipMacroValidation"

# For fastlane
build_app(
  xcargs: "OTHER_SWIFT_FLAGS='-skipMacroValidation'"
)
```

This flag helps bypass macro validation in CI environments where the full macro compilation context might not be available.

### Default Value Behavior for UserDefaults and iCloud Key-Value Store

All persistent properties (those marked with @DefaultsBacked or @CloudBacked, either explicitly or implicitly) must be declared with default values. The framework captures these declaration-time defaults and maintains them as immutable model defaults throughout the object's lifetime.

Fallback order depends on the backing store:

- `@ObservableDefaults` (`UserDefaults`)
  1. Persisted value in the selected `UserDefaults` domain
  2. Value provided by `UserDefaults.register(defaults:)`
  3. Declaration-time model default captured by ObservableDefaults
- `@ObservableCloud` (`NSUbiquitousKeyValueStore`)
  1. Persisted cloud value
  2. Declaration-time model default captured by ObservableDefaults

This means `removeObject(forKey:)` does not always revert to the declaration default for `UserDefaults`. If the key has a registered default, that registered default is used first.

```swift
@ObservableDefaults(autoInit: false) // @ObservableCloud(autoInit: false) is the same
class User {
    var username = "guest"      // ← Declaration default: "guest"
    var age: Int = 18          // ← Declaration default: 18

    init(username: String, age: Int) {
        self.username = username  // Current value: "alice", default remains: "guest"
        self.age = age           // Current value: 25, default remains: 18
        // ... other initialization code, like observerStarter(observableKeysBlacklist: [])
    }
}

let user = User(username: "alice", age: 25)

// Current state:
// - username current value: "alice"
// - username default value: "guest" (immutable)
// - age current value: 25
// - age default value: 18 (immutable)

user.username = "bob"  // Changes current value, default value stays "guest"

let defaults = UserDefaults.standard
defaults.register(defaults: ["username": "registered-user"])
defaults.set("bob", forKey: "username")
defaults.set(25, forKey: "age")
defaults.removeObject(forKey: "username")
defaults.removeObject(forKey: "age")

print(user.username)  // "registered-user" (registered default wins)
print(user.age)       // 18 (no registered default, so declaration default is used)
```

> **Recommendation**: Unless you have specific requirements, use `autoInit: true` (default) to generate the standard initializer automatically. This helps avoid the misconception that default values can be modified through custom initializers.

### Swift 6.2 and Default Actor Isolation

**Important**: If your project or target has `defaultIsolation` set to `MainActor`, you **must** set the `defaultIsolationIsMainActor` parameter to `true` for proper Swift 6 concurrency compatibility:

```swift
// For projects with defaultIsolation = MainActor
@ObservableDefaults(defaultIsolationIsMainActor: true)
class Settings {
    var name: String = "Fatbobman"
    var age: Int = 20
}

@ObservableCloud(defaultIsolationIsMainActor: true)
class CloudSettings {
    var username: String = "Fatbobman"
    var theme: String = "light"
}
```

**Why this is required**:
- Swift 6.2's `defaultIsolation MainActor` setting affects how the compiler handles concurrency
- Without this parameter, you may encounter `@Sendable` conflicts in MainActor environments
- The parameter ensures proper notification handling and deinit isolation

**When to use**:
- ✅ Your project has `defaultIsolation` set to `MainActor` in build settings
- ✅ You're experiencing Swift 6 concurrency compilation errors
- ❌ Your project uses the default `nonisolated` setting (parameter not needed)

### App Groups and Cross-Process Synchronization

When using App Groups to share UserDefaults between your main app and extensions (widgets, app extensions), you need special configuration to ensure proper cross-process notification handling.

#### The Problem

By default, `@ObservableDefaults` only listens to UserDefaults change notifications from its specific UserDefaults instance. When using App Groups:

- Your main app creates: `UserDefaults(suiteName: "group.myapp")`
- Your widget creates: `UserDefaults(suiteName: "group.myapp")`

Even though both access the same data store, they are different object instances. When the widget modifies data, the main app won't automatically receive notifications about the changes.

#### The Solution

Use the `limitToInstance: false` parameter to enable cross-process notifications:

```swift
@ObservableDefaults(
    suiteName: "group.com.yourcompany.app",
    prefix: "myapp_",  // IMPORTANT: Use a unique prefix
    limitToInstance: false  // Enable cross-process notifications
)
class SharedSettings {
    var lastUpdate: Date = Date()
    var displayCount: Int = 0
}
```

#### Critical: Always Use a Unique Prefix

When `limitToInstance: false`, the macro listens to ALL UserDefaults change notifications from the entire system, not just your specific suite. This means it will receive notifications from:

- `UserDefaults.standard`
- Other App Groups (`group.otherapp`)
- Any other UserDefaults instances in your app

**The prefix acts as a filter** to ensure your class only responds to changes from your intended suiteName:

```swift
// App Group suite
@ObservableDefaults(
    suiteName: "group.myapp",
    prefix: "myapp_",  // Only respond to keys starting with "myapp_"
    limitToInstance: false
)
class AppGroupSettings {
    var sharedData: String = "data"  // Stored as "myapp_sharedData"
}

// Different App Group suite
@ObservableDefaults(
    suiteName: "group.anotherapp",
    prefix: "anotherapp_",  // Only respond to keys starting with "anotherapp_"
    limitToInstance: false
)
class AnotherAppSettings {
    var sharedData: String = "other"  // Stored as "anotherapp_sharedData"
}
```

Without unique prefixes, your `AppGroupSettings` might incorrectly react to changes from `group.anotherapp` or `UserDefaults.standard`.

#### Performance Considerations

- **Default (`limitToInstance: true`)**: Better performance, only monitors changes from the specific UserDefaults instance. Recommended for single-process apps.
- **Cross-Process (`limitToInstance: false`)**: Necessary for App Groups but receives ALL system UserDefaults notifications. The prefix is essential to filter only relevant changes from your target suite.

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
