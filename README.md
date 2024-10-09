# ObservableDefaults

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

`ObservableDefaults` is a Swift library that integrates `UserDefaults` with the new SwiftUI Observation framework introduced in WWDC 2023. It provides a macro `@ObservableDefaults` that simplifies the management of `UserDefaults` data by automatically associating declared stored properties with `UserDefaults` keys. This allows for precise and efficient responsiveness to changes in `UserDefaults`, whether they originate from within the app or externally.

## Motivation

Managing multiple UserDefaults keys in SwiftUI can lead to bloated code and increase the risk of errors. While @AppStorage simplifies handling single UserDefaults keys, it doesn't scale well for multiple keys or offer precise view updates. With the introduction of the Observation framework, there's a need for a solution that efficiently bridges UserDefaults with SwiftUI's state management.

ObservableDefaults was created to address these challenges by providing a comprehensive and practical solution. It leverages macros to reduce boilerplate code and ensures that your SwiftUI views respond accurately to changes in UserDefaults.

For an in-depth discussion on the limitations of @AppStorage and the motivation behind ObservableDefaults, you can read the full article on [my blog](https://fatbobman.com/en/posts/userdefaults-and-observation).

## Features

- Seamless integration with the SwiftUI Observation framework.
- Automatic synchronization of properties with `UserDefaults`.
- Precise notifications for property changes, reducing unnecessary view updates.
- Customizable behavior through additional macros and parameters.
- Support for property-specific `UserDefaults` keys and prefixes.

## Installation

You can add `ObservableDefaults` to your project using Swift Package Manager:

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL: `https://github.com/fatbobman/ObservableDefaults`
3. Select the package and add it to your project.

## Usage

### Basic Example

After importing `ObservableDefaults`, you can annotate your class with `@ObservableDefaults` to automatically manage `UserDefaults` synchronization:

```swift
import ObservableDefaults

@ObservableDefaults
class Settings {
    var name: String = "Fatbobman"
    var age: Int = 20
}
```

This macro automatically:

- Associates the `name` and `age` properties with `UserDefaults` keys.
- Listens for external changes to these keys and updates the properties accordingly.
- Notifies SwiftUI views of changes precisely, avoiding unnecessary redraws.

### Using in SwiftUI Views

You can use the `Settings` class in your SwiftUI views as follows:

```swift
import SwiftUI

struct ContentView: View {
    @State var settings = Settings()

    var body: some View {
        VStack {
            Text("Name: \(settings.name)")
            TextField("Enter name", text: $settings.name)
        }
        .padding()
    }
}
```

### Customizing Behavior with Additional Macros

The library provides additional macros for finer control:

- `@ObservableOnly`: The property is observable but not stored in `UserDefaults`.
- `@Ignore`: The property is neither observable nor stored in `UserDefaults`.
- `@DefaultsKey`: Specifies a custom `UserDefaults` key for the property.

#### Example

```swift
@ObservableDefaults
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"

    @ObservableOnly
    var age: Int = 20

    @Ignore
    var city: String = "Dalian"
}
```

In this example:

- `name` is stored in `UserDefaults` under the key `"fullName"`.
- `age` is observable but not stored in `UserDefaults`.
- `city` is neither observable nor stored in `UserDefaults`.

### Initializer and Parameters

If all properties have default values, you can use the automatically generated initializer:

```swift
public init(
    userDefaults: UserDefaults? = nil,
    ignoreExternalChanges: Bool? = nil,
    prefix: String? = nil
)
```

#### Parameters

- `userDefaults`: The `UserDefaults` instance to use (default is `.standard`).
- `ignoreExternalChanges`: If `true`, the instance ignores external `UserDefaults` changes (default is `false`).
- `prefix`: A prefix for all `UserDefaults` keys associated with this class.

#### Example Usage

```swift
@StateObject var settings = Settings(
    userDefaults: .standard,
    ignoreExternalChanges: false,
    prefix: "myApp_"
)
```

### Macro Parameters

You can also set parameters directly in the `@ObservableDefaults` macro:

- `userDefaults`: The `UserDefaults` instance to use.
- `ignoreExternalChanges`: Whether to ignore external changes.
- `prefix`: A prefix for `UserDefaults` keys.
- `autoInit`: Whether to automatically generate the initializer (default is `true`).

#### Example

```swift
@ObservableDefaults(autoInit: false, ignoreExternalChanges: true, prefix: "myApp_")
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"
}
```

### Custom Initializer

If you set `autoInit` to `false`, you need to create your own initializer and explicitly start listening for `UserDefaults` changes:

```swift
init() {
    // Start listening for changes
    observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix)
}
```

### Integrating with Other Observable Objects

It's recommended to manage `UserDefaults` data separately from your main application state:

```swift
@Observable
class AppState {
    var selection = 10
    var isLogin = false
    let settings = Settings()
}

struct ContentView: View {
    @StateObject var state = AppState()

    var body: some View {
        VStack(spacing: 30) {
            Text("Name: \(state.settings.name)")
            Button("Modify Instance Property") {
                state.settings.name = "User \(Int.random(in: 0...1000))"
            }
            Button("Modify UserDefaults Directly") {
                UserDefaults.standard.set("User \(Int.random(in: 0...1000))", forKey: "name")
            }
        }
        .buttonStyle(.bordered)
    }
}
```

## Important Notes

- **External Changes**: By default, `ObservableDefaults` instances respond to external changes in `UserDefaults`. You can disable this by setting `ignoreExternalChanges` to `true`.
- **Key Prefixes**: Use the `prefix` parameter to prevent key collisions when multiple classes use the same property names.
- **Custom Keys**: Use `@DefaultsKey` to specify custom keys for properties.

## License

`ObservableDefaults` is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

Special thanks to the Swift community for their continuous support and contributions.

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://buymeacoffee.com/fatbobman)

