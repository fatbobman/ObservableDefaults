# ObservableDefaults

ObservableDefaults 通过类宏将 Swift Observation 与 UserDefaults 及 iCloud 键值存储连接起来。

![Swift](https://img.shields.io/badge/Swift-6%2B-orange?style=flat) ![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B%20%7C%20Mac%20Catalyst%2017%2B%20%7C%20watchOS%2010%2B%20%7C%20tvOS%2017%2B%20%7C%20visionOS%201%2B-blue?style=flat) [![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE) [![DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/fatbobman/ObservableDefaults)

[English](README.md) | 中文

## 动机

在 SwiftUI 中管理大量 UserDefaults 键往往会产生重复代码，而 `@AppStorage` 以单个值为中心，也不涵盖 iCloud 键值同步。Observation 同样需要属性级跟踪，避免无关变化使整个视图失效。

ObservableDefaults 使用宏将模型属性连接到 `UserDefaults` 或 `NSUbiquitousKeyValueStore`，同时保留精确的 Observation 更新，并处理来自模型外部的存储变化。

若想了解设计背景以及与 `@AppStorage` 的深入比较，请阅读[在 SwiftUI 中用 Observation 框架实现 UserDefaults 数据持久化](https://fatbobman.com/posts/userdefaults-and-observation)。

## 特性

- `@ObservableDefaults` 将可观察属性持久化到 `UserDefaults`。
- `@ObservableCloud` 通过 `NSUbiquitousKeyValueStore` 同步可观察属性。
- 外部存储变化会生成属性级 Observation 更新。
- 自定义键、suite 名称与前缀支持应用特定的存储布局。
- Optional、Codable 与 RawRepresentable 值遵循文档所述的存储规则。
- 观察优先模式允许模型显式选择需要持久化的属性。
- 开发模式为预览与测试隔离云端模型。

## 快速开始

通过 Swift Package Manager 添加 ObservableDefaults：

```swift
dependencies: [
    .package(
        url: "https://github.com/fatbobman/ObservableDefaults.git",
        from: "1.8.8"
    )
]
```

声明一个属性可观察并由 `UserDefaults` 支持的类：

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

## 文档

- 想配置本地与云端宏、自定义键、存储类型或观察优先模式？请阅读[使用指南](Docs/Usage_zh.md)。
- 想了解默认值、预览、CI、Actor 隔离、App Group 或云端约束？请阅读[行为与集成说明](Docs/Behavior_zh.md)。

## 许可证

ObservableDefaults 基于 MIT 许可证发布。详情请参阅
[LICENSE](LICENSE)。

## Author

**Fatbobman (肘子)** — Blog: [fatbobman.com](https://fatbobman.com) · X: [@fatbobman](https://x.com/fatbobman)

## Support

If this project helps you, please consider supporting my work:

- 📮 Subscribe to [Fatbobman's Swift Weekly](https://weekly.fatbobman.com) — fresh Swift and Apple-ecosystem insights every week
- ☕️ [Buy Me a Coffee](https://buymeacoffee.com/fatbobman)
