# ObservableDefaults

[English](README.md) | 中文

![Swift 6](https://img.shields.io/badge/Swift-6-orange?logo=swift) ![iOS](https://img.shields.io/badge/iOS-17.0+-green) ![macOS](https://img.shields.io/badge/macOS-14.0+-green) ![watchOS](https://img.shields.io/badge/watchOS-10.0+-green) ![visionOS](https://img.shields.io/badge/visionOS-1.0+-green) ![tvOS](https://img.shields.io/badge/tvOS-17.0+-green) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/fatbobman/ObservableDefaults)

> 无缝集成 SwiftUI + Observation + UserDefaults + iCloud Key-Value Store

`ObservableDefaults` 是一个全面的 Swift 库，无缝集成了 **`UserDefaults`** 和 **`NSUbiquitousKeyValueStore`**（iCloud 键值存储）与 SwiftUI 的 Observation 框架。它提供了两个强大的宏 - `@ObservableDefaults` 用于本地 UserDefaults 管理，`@ObservableCloud` 用于云同步数据存储 - 通过自动关联声明的属性与其各自的存储系统来简化数据持久化。这使得无论数据变化来自应用内部、外部还是跨多个设备，都能实现精确且高效的响应。

## 动机

在 SwiftUI 中管理多个 UserDefaults 键和云同步数据可能导致代码臃肿并增加出错风险。虽然 @AppStorage 简化了单个 UserDefaults 键的处理，但它不能很好地扩展到多个键，缺乏云同步功能，也无法提供精确的视图更新。随着 Observation 框架的引入，需要一个综合解决方案来有效地连接本地和云存储与 SwiftUI 的状态管理。

ObservableDefaults 的创建就是为了解决这些挑战，通过提供完整的数据持久化解决方案。它利用宏来减少样板代码，并确保您的 SwiftUI 视图能够准确响应 UserDefaults 和 iCloud 数据的变化。

有关 @AppStorage 的局限性和 ObservableDefaults 背后动机的深入讨论，您可以阅读 [我的博客](https://fatbobman.com/posts/userdefaults-and-observation) 上的完整文章。

---

不要错过关于 Swift、SwiftUI、Core Data 和 SwiftData 的最新更新和优秀文章。订阅 **[肘子的 Swift 周报](https://weekly.fatbobman.com)** 并直接在您的收件箱中接收每周见解和有价值的内容。

---

## 特性

- **双重存储支持**: 无缝集成 `UserDefaults` 和 `NSUbiquitousKeyValueStore`（iCloud）
- **SwiftUI Observation**: 与 SwiftUI Observation 框架完全集成
- **自动同步**: 属性自动与其各自的存储系统同步
- **跨设备同步**: 云支持的属性在用户设备间自动同步
- **精确通知**: 属性级别的变化通知，减少不必要的视图更新
- **开发模式**: 支持测试，无需 CloudKit 容器要求
- **可自定义行为**: 通过附加宏和参数进行细粒度控制
- **自定义键和前缀**: 支持属性特定的存储键和全局前缀
- **Codable 支持**: 本地和云存储的复杂数据持久化
- **Optional 类型支持**: 完全支持具有 nil 值的 Optional 属性

## 安装

您可以使用 Swift Package Manager 将 `ObservableDefaults` 添加到您的项目中：

1. 在 Xcode 中，转到 **File > Add Packages...**
2. 输入仓库 URL：`https://github.com/fatbobman/ObservableDefaults`
3. 选择包并将其添加到您的项目中。

## 使用

### 使用 @ObservableDefaults 集成 UserDefaults

导入 `ObservableDefaults` 后，您可以用 `@ObservableDefaults` 注释您的类来自动管理 `UserDefaults` 同步：

```swift
import ObservableDefaults

@ObservableDefaults
class Settings {
    var name: String = "Fatbobman"
    var age: Int = 20
    var nickname: String? = nil  // 支持 Optional
}
```

https://github.com/user-attachments/assets/469d55e8-7468-44ac-b591-804c40815724

此宏自动：

- 将 `name` 和 `age` 属性与 `UserDefaults` 键关联。
- 监听这些键的外部变化并相应地更新属性。
- 精确地通知 SwiftUI 视图变化，避免不必要的重绘。

### 使用 @ObservableCloud 集成云存储

对于跨设备自动同步的云同步数据，使用 `@ObservableCloud` 宏：

```swift
import ObservableDefaults

@ObservableCloud
class CloudSettings {
    var number = 1
    var color: Colors = .red
    var style: FontStyle = .style1
    var cloudName: String? = nil  // 支持 Optional
}
```

https://github.com/user-attachments/assets/7e8dcf6b-3c8f-4bd3-8083-ff3c4a6bd6b0

[演示代码](https://gist.github.com/fatbobman/5ab86c35ac8cee93c8ac6ac4228a28a9)

此宏自动：

- 将属性与 `NSUbiquitousKeyValueStore` 关联以进行 iCloud 同步
- 监听来自其他设备的外部变化并相应地更新属性
- 提供与 `@ObservableDefaults` 相同的精确 SwiftUI 观察
- 支持开发模式，用于测试而无需 CloudKit 容器设置

### 在 SwiftUI 视图中使用

`@ObservableDefaults` 和 `@ObservableCloud` 类在 SwiftUI 视图中的工作方式相同：

```swift
import SwiftUI

struct ContentView: View {
    @State var settings = Settings()        // UserDefaults 支持
    @State var cloudSettings = CloudSettings()  // iCloud 支持

    var body: some View {
        VStack {
            // 本地设置
            Text("Name: \(settings.name)")
            TextField("Enter name", text: $settings.name)
            
            // 云同步设置
            Text("Username: \(cloudSettings.username)")
            TextField("Enter username", text: $cloudSettings.username)
        }
        .padding()
    }
}
```

### 使用附加宏自定义行为

#### 对于 @ObservableDefaults（UserDefaults）

该库提供了用于更精细控制的附加宏：

- `@ObservableOnly`: 属性可观察但不存储在 `UserDefaults` 中。
- `@Ignore`: 属性既不可观察也不存储在 `UserDefaults` 中。
- `@DefaultsKey`: 为属性指定自定义 `UserDefaults` 键。
- `@DefaultsBacked`: 属性存储在 `UserDefaults` 中并且可观察。

```swift
@ObservableDefaults
public class LocalSettings {
    @DefaultsKey(userDefaultsKey: "firstName")
    public var name: String = "fat"

    public var age = 109  // 自动由 UserDefaults 支持

    @ObservableOnly
    public var height = 190  // 仅可观察，不持久化

    @Ignore
    public var weight = 10  // 既不可观察也不持久化
}
```

#### 对于 @ObservableCloud（iCloud 存储）

类似的宏支持，具有云特定选项：

- `@ObservableOnly`: 属性可观察但不存储在 `NSUbiquitousKeyValueStore` 中。
- `@Ignore`: 属性既不可观察也不存储。
- `@CloudKey`: 为属性指定自定义 `NSUbiquitousKeyValueStore` 键。
- `@CloudBacked`: 属性存储在 `NSUbiquitousKeyValueStore` 中并且可观察。

```swift
@ObservableCloud
public class CloudSettings {
    @CloudKey(keyValueStoreKey: "user_display_name")
    public var username: String = "Fatbobman"

    public var theme: String = "light"  // 自动云支持

    @ObservableOnly
    public var localCache: String = ""  // 仅可观察，不同步到云

    @Ignore
    public var temporaryData: String = ""  // 既不可观察也不持久化
}
```

### 初始化器和参数

#### @ObservableDefaults 参数

如果所有属性都有默认值，您可以使用自动生成的初始化器：

```swift
public init(
    userDefaults: UserDefaults? = nil,
    ignoreExternalChanges: Bool? = nil,
    prefix: String? = nil
)
```

**参数：**

- `userDefaults`: 要使用的 `UserDefaults` 实例（默认为 `.standard`）。
- `ignoreExternalChanges`: 如果为 `true`，实例忽略外部 `UserDefaults` 变化（默认为 `false`）。
- `prefix`: 与此类关联的所有 `UserDefaults` 键的前缀。

#### @ObservableCloud 参数

云版本提供类似的初始化选项：

```swift
public init(
    prefix: String? = nil,
    syncImmediately: Bool = false,
    developmentMode: Bool = false
)
```

**参数：**

- `prefix`: 所有 `NSUbiquitousKeyValueStore` 键的前缀。
- `syncImmediately`: 如果为 `true`，在每次更改后强制立即同步。
- `developmentMode`: 如果为 `true`，使用内存存储而不是 iCloud 进行测试。

#### 使用示例

```swift
// UserDefaults 支持的设置
@State var settings = Settings(
    userDefaults: .standard,
    ignoreExternalChanges: false,
    prefix: "myApp_"
)

// 云支持的设置
@State var cloudSettings = CloudSettings(
    prefix: "myApp_",
    syncImmediately: true,
    developmentMode: false
)
```

### 宏参数

#### @ObservableDefaults 宏参数

您可以直接在 `@ObservableDefaults` 宏中设置参数：

- `userDefaults`: 要使用的 `UserDefaults` 实例。
- `ignoreExternalChanges`: 是否忽略外部变化。
- `prefix`: `UserDefaults` 键的前缀。
- `autoInit`: 是否自动生成初始化器（默认为 `true`）。
- `observeFirst`: 观察优先级模式（默认为 `false`）。

```swift
@ObservableDefaults(autoInit: false, ignoreExternalChanges: true, prefix: "myApp_")
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"
}
```

#### @ObservableCloud 宏参数

云宏提供类似的配置选项：

- `autoInit`: 是否自动生成初始化器（默认为 `true`）。
- `prefix`: `NSUbiquitousKeyValueStore` 键的前缀。
- `observeFirst`: 观察优先级模式（默认为 `false`）。
- `syncImmediately`: 是否强制立即同步（默认为 `false`）。
- `developmentMode`: 是否使用内存存储进行测试（默认为 `false`）。

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

### 云存储的开发模式

`@ObservableCloud` 宏支持开发模式，用于在没有 CloudKit 设置的情况下进行测试：

```swift
@ObservableCloud(developmentMode: true)
class CloudSettings {
    var setting1: String = "value1"  // 使用内存存储
    var setting2: Int = 42           // 使用内存存储
}
```

开发模式在以下情况下自动启用：

- 通过 `developmentMode: true` 显式设置
- 在 SwiftUI Previews 中运行（`XCODE_RUNNING_FOR_PREVIEWS` 环境变量）
- `OBSERVABLE_DEFAULTS_DEV_MODE` 环境变量设置为 "true"

### 自定义初始化器

如果您将任一宏的 `autoInit` 设置为 `false`，您需要创建自己的初始化器：

```swift
// 对于 @ObservableDefaults
init() {
    observerStarter()  // 开始监听 UserDefaults 变化
}

// 对于 @ObservableCloud
init() {
    // 仅在生产模式下启动云观察
    if !_developmentMode_ {
        _cloudObserver = CloudObservation(host: self, prefix: _prefix)
    }
}
```

### 观察优先模式

两个宏都支持"观察优先"模式，其中属性默认可观察，但只有显式标记的属性被持久化：

#### UserDefaults 观察优先模式

```swift
@ObservableDefaults(observeFirst: true)
public class LocalSettings {
    public var name: String = "fat"        // 仅可观察
    public var age = 109                   // 仅可观察

    @DefaultsBacked(userDefaultsKey: "myHeight")
    public var height = 190                // 可观察并持久化到 UserDefaults

    @Ignore
    public var weight = 10                 // 既不可观察也不持久化
}
```

#### 云观察优先模式

```swift
@ObservableCloud(observeFirst: true)
public class CloudSettings {
    public var localSetting: String = "local"     // 仅可观察
    public var tempData = "temp"                  // 仅可观察

    @CloudBacked(keyValueStoreKey: "user_theme")
    public var theme: String = "light"            // 可观察并同步到 iCloud

    @Ignore
    public var cache = "cache"                    // 既不可观察也不持久化
}
```

### 支持 Optional 类型

两个宏都完全支持 Optional 属性：

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

### 支持 Codable 类型

两个宏都支持遵循 `Codable` 的属性以进行复杂数据持久化：

#### 使用 Codable 的 UserDefaults

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

#### 使用 Codable 的云存储

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

### 与其他 Observable 对象集成

建议将存储数据与主应用程序状态分开管理：

```swift
@Observable
class ViewState {
    var selection = 10
    var isLogin = false
    let localSettings = LocalSettings()    // UserDefaults 支持
    let cloudSettings = CloudSettings()    // iCloud 支持
}

struct ContentView: View {
    @State var state = ViewState()

    var body: some View {
        VStack(spacing: 30) {
            // 本地设置
            Text("Local Name: \(state.localSettings.name)")
            Button("Modify Local Setting") {
                state.localSettings.name = "User \(Int.random(in: 0...1000))"
            }
            
            // 云设置
            Text("Cloud Username: \(state.cloudSettings.username)")
            Button("Modify Cloud Setting") {
                state.cloudSettings.username = "CloudUser \(Int.random(in: 0...1000))"
            }
        }
        .buttonStyle(.bordered)
    }
}
```

## 重要说明

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

所有持久化属性（那些明确或隐式标记为 @DefaultsBacked 或 @CloudBacked 的属性）必须用默认值声明。框架捕获这些声明时的默认值，并在对象的整个生命周期内将它们保持为不可变的回退值。当底层存储（UserDefaults 或 iCloud Key-Value Store）中缺少键时，属性会自动恢复到这些保留的默认值，确保行为一致，无论外部存储修改如何。

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

// 如果 UserDefaults 键被外部删除：
UserDefaults.standard.removeObject(forKey: "username")
UserDefaults.standard.removeObject(forKey: "age")

print(user.username)  // "guest"（恢复到声明默认值）
print(user.age)       // 18（恢复到声明默认值）
```

> **建议**: 除非您有特定要求，否则使用 `autoInit: true`（默认）来自动生成标准初始化器。这有助于避免认为可以通过自定义初始化器修改默认值的误解。

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

## 许可证

`ObservableDefaults` 在 MIT 许可证下发布。详情请参阅 [LICENSE](LICENSE)。

---

## 致谢

特别感谢 Swift 社区的持续支持和贡献。

## 支持项目

- [🎉 订阅我的 Swift 周报](https://weekly.fatbobman.com)
- [☕️ 给我买杯咖啡](https://buymeacoffee.com/fatbobman)

## Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=fatbobman/ObservableDefaults&type=Date)](https://star-history.com/#fatbobman/ObservableDefaults&Date)