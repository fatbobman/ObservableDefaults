# ObservableDefaults 行为与集成说明

[English](Behavior.md) | 中文

### 在 SwiftUI #Preview 中使用

当在 SwiftUI 的 `#Preview` 和 `@Previewable` 中使用 `@ObservableCloud` 类时，您可能会遇到错误："cannot be constructed because it has no accessible initializers"。这是因为 `@Previewable` 需要一个无参数的初始化器。以下是两种解决方案：

#### 解决方案 1：添加便捷初始化器

```swift
@ObservableCloud
class CloudSettings {
    var item: Bool = true

    // 为 Preview 支持添加这个便捷初始化器
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

注意：在便捷初始化器中设置 `developmentMode: true` 可确保 Preview 使用内存存储而不需要 CloudKit，这对于 Preview 环境来说是理想的。

#### 解决方案 2：使用单例模式

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

### CI/CD 配置

在 CI/CD 环境中使用 ObservableDefaults 时，您可能需要在构建命令中添加 `-skipMacroValidation` 标志以避免宏验证问题：

```bash
# 对于 Swift CLI
swift build -Xswiftc -skipMacroValidation
swift test -Xswiftc -skipMacroValidation

# 对于 xcodebuild
xcodebuild build OTHER_SWIFT_FLAGS="-skipMacroValidation"

# 对于 fastlane
build_app(
  xcargs: "OTHER_SWIFT_FLAGS='-skipMacroValidation'"
)
```

此标志有助于在 CI 环境中绕过宏验证，在这些环境中可能无法提供完整的宏编译上下文。

### UserDefaults 和 iCloud Key-Value Store 的默认值行为

所有持久化属性（那些明确或隐式标记为 @DefaultsBacked 或 @CloudBacked 的属性）都必须用默认值声明。框架会捕获这些声明时的默认值，并在对象整个生命周期内将其保持为不可变的模型默认值。

回退顺序取决于底层存储：

- `@ObservableDefaults`（`UserDefaults`）
  1. 所选 `UserDefaults` 域中的持久化值
  2. 通过 `UserDefaults.register(defaults:)` 注册的默认值
  3. ObservableDefaults 捕获的声明时模型默认值
- `@ObservableCloud`（`NSUbiquitousKeyValueStore`）
  1. 云端持久化值
  2. ObservableDefaults 捕获的声明时模型默认值

这意味着对于 `UserDefaults`，`removeObject(forKey:)` 并不一定直接回退到声明默认值。如果该 key 存在 registered default，会优先使用 registered default。

```swift
@ObservableDefaults(autoInit: false) // @ObservableCloud(autoInit: false) 相同
class User {
    var username = "guest"      // ← 声明默认值："guest"
    var age: Int = 18          // ← 声明默认值：18

    init(username: String, age: Int) {
        self.username = username  // 当前值："alice"，默认值保持："guest"
        self.age = age           // 当前值：25，默认值保持：18
        // ... 其他初始化代码，如 observerStarter(observableKeysBlacklist: [])
    }
}

let user = User(username: "alice", age: 25)

// 当前状态：
// - username 当前值："alice"
// - username 默认值："guest"（不可变）
// - age 当前值：25
// - age 默认值：18（不可变）

user.username = "bob"  // 更改当前值，默认值保持 "guest"

let defaults = UserDefaults.standard
defaults.register(defaults: ["username": "registered-user"])
defaults.set("bob", forKey: "username")
defaults.set(25, forKey: "age")
defaults.removeObject(forKey: "username")
defaults.removeObject(forKey: "age")

print(user.username)  // "registered-user"（优先使用 registered default）
print(user.age)       // 18（没有 registered default，因此回退到声明默认值）
```

> **建议**: 除非您有特定要求，否则使用 `autoInit: true`（默认）来自动生成标准初始化器。这有助于避免认为可以通过自定义初始化器修改默认值的误解。

### Swift 6.2 和默认 Actor 隔离

**重要**: 如果您的项目或目标将 `defaultIsolation` 设置为 `MainActor`，您**必须**将 `defaultIsolationIsMainActor` 参数设置为 `true` 以获得正确的 Swift 6 并发兼容性：

```swift
// 对于 defaultIsolation = MainActor 的项目
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

**为什么需要这个参数**:
- Swift 6.2 的 `defaultIsolation MainActor` 设置影响编译器如何处理并发
- 如果没有此参数，您可能在 MainActor 环境中遇到 `@Sendable` 冲突
- 该参数确保正确的通知处理和 deinit 隔离

**何时使用**:
- ✅ 您的项目在构建设置中将 `defaultIsolation` 设置为 `MainActor`
- ✅ 您遇到了 Swift 6 并发编译错误
- ❌ 您的项目使用默认的 `nonisolated` 设置（不需要参数）

### App Groups 和跨进程同步

当使用 App Groups 在主应用和扩展（小组件、应用扩展）之间共享 UserDefaults 时，您需要特殊配置以确保正确的跨进程通知处理。

#### 问题所在

默认情况下，`@ObservableDefaults` 仅监听来自其特定 UserDefaults 实例的 UserDefaults 变更通知。当使用 App Groups 时：

- 您的主应用创建：`UserDefaults(suiteName: "group.myapp")`
- 您的小组件创建：`UserDefaults(suiteName: "group.myapp")`

即使两者访问相同的数据存储，它们是不同的对象实例。当小组件修改数据时，主应用不会自动接收到关于变更的通知。

#### 解决方案

使用 `limitToInstance: false` 参数启用跨进程通知：

```swift
@ObservableDefaults(
    suiteName: "group.com.yourcompany.app",
    prefix: "myapp_",  // 重要：使用唯一前缀
    limitToInstance: false  // 启用跨进程通知
)
class SharedSettings {
    var lastUpdate: Date = Date()
    var displayCount: Int = 0
}
```

#### 关键：必须使用唯一前缀

当 `limitToInstance: false` 时，宏会监听来自整个系统的所有 UserDefaults 变更通知，而不仅仅是您特定的套件。这意味着它会接收来自：

- `UserDefaults.standard`
- 其他 App Groups（`group.otherapp`）
- 您应用中的任何其他 UserDefaults 实例

**前缀充当过滤器**，确保您的类仅响应来自预期 suiteName 的变更：

```swift
// App Group 套件
@ObservableDefaults(
    suiteName: "group.myapp",
    prefix: "myapp_",  // 仅响应以 "myapp_" 开头的键
    limitToInstance: false
)
class AppGroupSettings {
    var sharedData: String = "data"  // 存储为 "myapp_sharedData"
}

// 不同的 App Group 套件
@ObservableDefaults(
    suiteName: "group.anotherapp",
    prefix: "anotherapp_",  // 仅响应以 "anotherapp_" 开头的键
    limitToInstance: false
)
class AnotherAppSettings {
    var sharedData: String = "other"  // 存储为 "anotherapp_sharedData"
}
```

如果没有唯一前缀，您的 `AppGroupSettings` 可能会错误地响应来自 `group.anotherapp` 或 `UserDefaults.standard` 的变更。

#### 性能考虑

- **默认（`limitToInstance: true`）**：更好的性能，仅监控来自特定 UserDefaults 实例的变更。建议用于单进程应用。
- **跨进程（`limitToInstance: false`）**：App Groups 所必需，但会接收所有系统 UserDefaults 通知。前缀对于过滤目标套件中的相关变更至关重要。

### 一般说明

- **外部变化**: 默认情况下，两个宏都响应其各自存储系统中的外部变化。
- **键前缀**: 当多个类使用相同的属性名称时，使用 `prefix` 参数防止键冲突。
- **自定义键**: 使用 `@DefaultsKey` 或 `@CloudKey` 为属性指定自定义键。
- **前缀字符**: 前缀不能包含 '.' 字符。

### 云特定说明

- **iCloud 账户**: 云存储需要活跃的 iCloud 账户和网络连接。
- **存储限制**: `NSUbiquitousKeyValueStore` 有 1MB 总存储限制和 1024 键限制。
- **同步**: 根据网络条件，更改可能需要时间才能在设备间传播。
- **开发模式**: 使用开发模式进行测试，无需 CloudKit 容器设置。
- **数据迁移**: 部署后更改属性名称或自定义键可能导致云数据变得不可访问。
- **直接 NSUbiquitousKeyValueStore 修改**: 使用 `NSUbiquitousKeyValueStore.default.set()` 直接修改值不会在 ObservableCloud 类中触发本地属性更新。这是由于 NSUbiquitousKeyValueStore 的通信机制，它不会为本地修改发送通知。始终通过 ObservableCloud 实例修改属性以确保正确的同步和视图更新。
