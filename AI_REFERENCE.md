# AI Reference for ObservableDefaults

> **AI-focused technical documentation for understanding and working with the ObservableDefaults Swift library**

## Project Overview

ObservableDefaults is a Swift 6 library that seamlessly integrates UserDefaults and NSUbiquitousKeyValueStore (iCloud Key-Value Storage) with SwiftUI's Observation framework using Swift macros. It provides two primary macros for automatic property persistence and observation.

## Core Architecture

### Dual Storage System
- **@ObservableDefaults**: UserDefaults-based local storage
- **@ObservableCloud**: NSUbiquitousKeyValueStore-based cloud storage with cross-device sync

### Macro-Driven Code Generation
Both macros generate:
1. SwiftUI Observation framework integration (`_$observationRegistrar`)
2. Property getter/setter accessors with storage backend
3. External change observation via NotificationCenter
4. Configuration properties and optional initializers

## Directory Structure

```
Sources/
├── ObservableDefaults/
│   ├── Macros.swift                 # Macro definitions and documentation
│   ├── module.swift                 # Re-exports Observation framework
│   ├── UserDefaults/
│   │   ├── UserDefaultsWrapper.swift           # Type-safe UserDefaults wrapper
│   │   └── UserDefaultsPropertyListValue.swift # Supported types
│   ├── NSUbiquitousKeyValueStore/
│   │   ├── NSUbiquitousKeyValueStoreWrapper.swift    # iCloud wrapper  
│   │   ├── CloudPropertyListValue.swift             # Cloud-supported types
│   │   ├── ObservableDefaultsCloudStoreProtocol.swift
│   │   └── MockUbiquitousKeyValueStore.swift        # Development mode mock
│   └── Utils/
└── ObservableDefaultsMacros/
    ├── Plugins.swift                # Compiler plugin registration
    ├── Helper/
    │   ├── Diagnostic.swift         # Error reporting
    │   ├── MacroType.swift          # Macro type definitions
    │   └── Syntax.swift             # SwiftSyntax extensions
    └── Macros/
        ├── ObservableDefaultsMacro.swift   # UserDefaults main macro
        ├── ObservableCloudMacro.swift      # iCloud main macro
        ├── DefaultsBackedMacro.swift       # Property-level UserDefaults
        ├── CloudBackedMacro.swift          # Property-level iCloud
        ├── DefaultsKeyMacro.swift          # Custom UserDefaults keys
        ├── CloudKeyMacro.swift             # Custom iCloud keys
        ├── ObservableOnlyMacro.swift       # Observable without persistence
        └── IgnoreMacro.swift               # Skip observation and persistence
```

## Key Implementation Details

### Macro Code Generation Pattern

Both primary macros (`@ObservableDefaults` and `@ObservableCloud`) follow this pattern:

1. **MemberMacro**: Generates class members
   - `_$observationRegistrar`: SwiftUI observation support
   - `access()` and `withMutation()`: Precise view updates
   - Storage configuration properties (`_userDefaults`, `_prefix`, etc.)
   - External change observer classes
   - Optional auto-generated initializer

2. **ExtensionMacro**: Makes class conform to `Observable`

3. **MemberAttributeMacro**: Auto-applies property macros based on mode
   - Standard mode: Auto-adds `@DefaultsBacked`/`@CloudBacked`
   - Observe First mode: Auto-adds `@ObservableOnly` unless explicitly backed

### Property Accessor Generation

Property macros generate:
```swift
// Generated for each backed property
private var _propertyName: Type = defaultValue

var propertyName: Type {
    get {
        access(keyPath: \.propertyName)
        return Wrapper.getValue(key, _propertyName, store)
    }
    set {
        withMutation(keyPath: \.propertyName) {
            if shouldSetValue(_propertyName, newValue) {
                Wrapper.setValue(key, newValue, store)
                _propertyName = newValue
            }
        }
    }
}
```

### External Change Observation

**UserDefaults**: Uses `UserDefaults.didChangeNotification`
**iCloud**: Uses `NSUbiquitousKeyValueStore.didChangeExternallyNotification`

Both create observer classes that monitor specific keys and trigger `withMutation()` for affected properties.

### MainActor Support

Both macros detect `@MainActor` attributes and generate appropriate isolation:
- With `@MainActor`: Uses `MainActor.assumeIsolated` in notification handlers
- Without `@MainActor`: Direct property access in handlers

## Supported Types

### UserDefaults Types
- Basic: `String`, `Int`, `Bool`, `Double`, `Float`, `Data`, `URL`, `[String]`, `[Any]`
- RawRepresentable: Enums with basic raw values
- Codable: Custom types via `Codable`
- Optionals: All above types as optionals

### iCloud Types
- Similar to UserDefaults but via `CloudPropertyListValue` protocols
- 1MB total storage limit, 1024 key limit
- Development mode uses memory storage for testing

## Operation Modes

### Standard Mode (Default)
- Properties automatically get storage backing
- `@ObservableDefaults`: Auto-applies `@DefaultsBacked`
- `@ObservableCloud`: Auto-applies `@CloudBacked`

### Observe First Mode (`observeFirst: true`)
- Properties are observable by default, storage is explicit
- Auto-applies `@ObservableOnly` unless marked with backing macros
- Useful for mixed observable/persistent properties

## Development Patterns

### Initialization Patterns
```swift
// Auto-generated initializer (autoInit: true - default)
@ObservableDefaults
class Settings {
    var name: String = "default"
}

// Custom initializer (autoInit: false)
@ObservableDefaults(autoInit: false)
class Settings {
    var name: String = "default"
    
    init() {
        observerStarter() // Must call for external change observation
    }
}
```

### Cloud Development Mode
Automatically enabled when:
- `developmentMode: true` parameter
- `XCODE_RUNNING_FOR_PREVIEWS` environment variable
- `OBSERVABLE_DEFAULTS_DEV_MODE=true` environment variable

### Key Naming Strategy
1. `@DefaultsKey(userDefaultsKey:)` or `@CloudKey(keyValueStoreKey:)` parameter
2. Property name as fallback
3. Optional prefix applied: `prefix + key`

### External Change Handling
- By default, responds to external changes
- Can disable globally: `ignoreExternalChanges: true`
- Can disable per-property: `ignoredKeyPathsForExternalUpdates` parameter

## Code Modification Guidelines

### When Adding New Features

1. **New Property Types**: 
   - Extend `UserDefaultsPropertyListValue` or `CloudPropertyListValue`
   - Add corresponding `UserDefaultsWrapper` or cloud wrapper methods
   - Update macro type checking logic

2. **New Macro Parameters**:
   - Add to enum constants in macro implementation
   - Extend `extractProperty()` method
   - Update member generation logic

3. **New Property Macros**:
   - Create new macro type in `MacroType.swift`
   - Implement accessor generation pattern
   - Add to compiler plugin registration

### Testing Patterns
- Use `UserDefaults.getTestInstance(suiteName:)` for isolation
- Cloud tests use development mode for deterministic behavior
- `tracking()` helper validates observation behavior
- Tests cover external change scenarios

### Performance Considerations
- Properties use lazy loading from storage
- Default values cached in private `_property` variables
- `shouldSetValue()` overloads prevent unnecessary storage writes
- External change observation batched via NotificationCenter

## Architecture Guidelines

### ⚠️ CRITICAL: Never Mix Macros on Single Class

**DO NOT** apply both `@ObservableDefaults` and `@ObservableCloud` to the same class. This creates conflicts and unpredictable behavior.

**CORRECT APPROACH**: Use separate classes for different storage types, then compose them:

```swift
// ✅ Separate classes for different storage types
@ObservableDefaults
class LocalSettings {
    var lastOpenedDocument: String = ""
    var windowFrame: CGRect = .zero
}

@ObservableCloud  
class CloudSettings {
    var username: String = "Guest"
    var theme: Theme = .light
    var preferences: UserPreferences = UserPreferences()
}

// ✅ Composition class for unified access
@Observable
class AppSettings {
    let local = LocalSettings()
    let cloud = CloudSettings()
    
    // Optional: Convenience computed properties
    var username: String {
        get { cloud.username }
        set { cloud.username = newValue }
    }
}
```

This pattern provides:
- Clear separation of storage concerns
- Independent configuration of each storage type  
- Predictable observation behavior
- Easy testing and debugging

## Common Pitfalls for AI

1. **Macro Mixing**: NEVER apply both macros to the same class - use composition instead
2. **Class-Only Restriction**: Both macros only work on classes, not structs
3. **Default Value Requirement**: All backed properties must have default values
4. **Prefix Validation**: Prefixes cannot contain '.' characters (KVO limitation)
5. **Development Mode**: Remember to enable for testing cloud features
6. **Observe First Confusion**: Properties are observable-only unless explicitly backed
7. **External Change Race**: Direct `NSUbiquitousKeyValueStore.set()` won't trigger updates
8. **Swift 6 Concurrency**: Macros generate `nonisolated` methods for cross-actor access

## Integration Examples

### Recommended Architecture Pattern
```swift
// ✅ Separate storage classes
@ObservableDefaults
class LocalSettings {
    var windowFrame: CGRect = .zero
    var recentFiles: [String] = []
    var isDarkMode: Bool = false
}

@ObservableCloud
class CloudSettings {
    var username: String = "Guest"
    var syncEnabled: Bool = true
    var preferences: UserPreferences = UserPreferences()
}

// ✅ Unified app state with composition
@Observable
class AppState {
    let local = LocalSettings()
    let cloud = CloudSettings()
    
    // App-specific transient state
    var isLoading: Bool = false
    var selectedTab: Tab = .home
}

// ✅ SwiftUI integration
struct ContentView: View {
    @State private var appState = AppState()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            SettingsView(appState: appState)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
    }
}

struct SettingsView: View {
    let appState: AppState
    
    var body: some View {
        Form {
            Section("Local Settings") {
                Toggle("Dark Mode", isOn: $appState.local.isDarkMode)
            }
            
            Section("Cloud Settings") {
                TextField("Username", text: $appState.cloud.username)
                Toggle("Sync Enabled", isOn: $appState.cloud.syncEnabled)
            }
        }
    }
}
```

### Observe First Mode Example
```swift
@ObservableDefaults(observeFirst: true)
class MixedSettings {
    var tempSelection: Int = 0          // Observable only
    
    @DefaultsBacked
    var persistentSetting: String = ""  // UserDefaults backed
    
    @ObservableOnly
    var computedValue: String = ""      // Observable only (explicit)
    
    @Ignore
    var internalState: Bool = false     // Neither observable nor persistent
}
```

### Development Mode for Testing
```swift
@ObservableCloud(developmentMode: true)
class TestCloudSettings {
    var setting1: String = "test"
    var setting2: Int = 42
}

// In tests or previews
let testSettings = TestCloudSettings() // Uses memory storage
```

This documentation should provide AI systems with the deep understanding needed to work effectively with the ObservableDefaults codebase.
