# ObservableDefaults

ObservableDefaults connects Swift Observation to UserDefaults and iCloud key-value storage through class macros.

![Swift](https://img.shields.io/badge/Swift-6%2B-orange?style=flat) ![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B%20%7C%20Mac%20Catalyst%2017%2B%20%7C%20watchOS%2010%2B%20%7C%20tvOS%2017%2B%20%7C%20visionOS%201%2B-blue?style=flat) [![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE) [![DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/fatbobman/ObservableDefaults)

English | [中文](README_zh.md)

## Motivation

Managing many UserDefaults keys in SwiftUI often creates repetitive code, while `@AppStorage` is centered on individual values and does not cover iCloud key-value synchronization. Observation also benefits from property-level tracking so unrelated changes do not invalidate a whole view.

ObservableDefaults uses macros to connect model properties to `UserDefaults` or `NSUbiquitousKeyValueStore`, while preserving precise Observation updates and handling changes originating outside the model.

For the design background and an in-depth comparison with `@AppStorage`, read [UserDefaults and Observation](https://fatbobman.com/en/posts/userdefaults-and-observation).

## Features

- `@ObservableDefaults` persists observable properties in `UserDefaults`.
- `@ObservableCloud` synchronizes observable properties through `NSUbiquitousKeyValueStore`.
- External storage changes produce property-level Observation updates.
- Custom keys, suite names, and prefixes support application-specific storage layouts.
- Optional, Codable, and RawRepresentable values are supported through documented storage rules.
- Observe-first mode lets a model opt properties into persistence explicitly.
- Development mode isolates cloud-backed models for previews and tests.

## Quick Start

Add ObservableDefaults with Swift Package Manager:

```swift
dependencies: [
    .package(
        url: "https://github.com/fatbobman/ObservableDefaults.git",
        from: "1.8.8"
    )
]
```

Declare a class whose properties are observable and backed by `UserDefaults`:

```swift
import ObservableDefaults

@ObservableDefaults
final class Settings {
    var username = "Guest"
    var launchCount = 0
}

let settings = Settings()
settings.launchCount += 1
```

## Documentation

- Want to configure local and cloud macros, keys, storage types, or observe-first mode? Read the [Usage Guide](Docs/Usage.md).
- Want to understand defaults, previews, CI, actor isolation, App Groups, or cloud constraints? Read [Behavior and Integration Notes](Docs/Behavior.md).

## License

ObservableDefaults is available under the MIT license. See the
[LICENSE](LICENSE) file for more info.

## Author

**Fatbobman (肘子)** — Blog: [fatbobman.com](https://fatbobman.com) · X: [@fatbobman](https://x.com/fatbobman)

## Support

If this project helps you, please consider supporting my work:

- 📮 Subscribe to [Fatbobman's Swift Weekly](https://weekly.fatbobman.com) — fresh Swift and Apple-ecosystem insights every week
- ☕️ [Buy Me a Coffee](https://buymeacoffee.com/fatbobman)
