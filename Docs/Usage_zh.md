# ObservableDefaults 使用指南

[English](Usage.md) | 中文

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
- `@DefaultsBacked` 不支持 `willSet` / `didSet`。

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
- `@CloudBacked` 不支持 `willSet` / `didSet`。

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

当 `autoInit: true` 时，宏会为上文的 `Settings` 类生成以下初始化器：

```swift
public init(
    userDefaults: Foundation.UserDefaults? = nil,
    ignoreExternalChanges: Bool? = nil,
    prefix: String? = nil,
    ignoredKeyPathsForExternalUpdates: [PartialKeyPath<Settings>] = []
)
```

**参数：**

- `userDefaults`: 实例级存储覆盖值。传入 `nil` 时保留宏的 `suiteName` 所选择的存储；未配置 suite 时使用 `.standard`。
- `ignoreExternalChanges`: 实例级覆盖值。传入 `nil` 时保留外层宏的 `ignoreExternalChanges` 值。
- `prefix`: 实例级键前缀覆盖值。传入 `nil` 时保留外层宏的 `prefix` 值。
- `ignoredKeyPathsForExternalUpdates`: 此实例中不参与外部存储更新处理的属性（默认为空）。

#### @ObservableCloud 参数

使用默认 `@ObservableCloud` 配置时，宏会生成：

```swift
public init(
    prefix: String? = nil,
    syncImmediately: Bool = false,
    developmentMode: Bool = false
)
```

**参数：**

- `prefix`: 实例级键前缀覆盖值。传入 `nil` 时保留外层宏的 `prefix` 值。
- `syncImmediately`: 控制每次写入后是否强制立即同步。
- `developmentMode`: 选择内存支持的开发存储，而不是 iCloud 存储。

`syncImmediately` 与 `developmentMode` 的生成默认字面值与外层宏传入的值一致。例如，`@ObservableCloud(syncImmediately: true)` 会生成 `syncImmediately: Bool = true`；显式传入初始化器参数时，仍会覆盖该生成默认值。

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

- `suiteName`: `UserDefaults` 的 suite 名称（默认为空，即使用 `.standard`）。
- `ignoreExternalChanges`: 是否忽略外部变化。
- `prefix`: `UserDefaults` 键的前缀。
- `autoInit`: 是否自动生成初始化器（默认为 `true`）。
- `observeFirst`: 观察优先级模式（默认为 `false`）。
- `limitToInstance`: 是否限制观察特定的 UserDefaults 实例（默认为 `true`）。设置为 `false` 以支持 App Group 跨进程同步。
- `defaultIsolationIsMainActor`: 目标是否以 MainActor 作为默认隔离（默认为 `false`）。

```swift
@ObservableDefaults(autoInit: false, ignoreExternalChanges: true, prefix: "myApp_")
class Settings {
    @DefaultsKey(userDefaultsKey: "fullName")
    var name: String = "Fatbobman"
}

// App Group 跨进程同步
@ObservableDefaults(
    suiteName: "group.myapp",
    prefix: "myapp_",
    limitToInstance: false
)
class SharedSettings {
    var lastUpdate: Date = Date()
}
```

#### @ObservableCloud 宏参数

云宏提供类似的配置选项：

- `autoInit`: 是否自动生成初始化器（默认为 `true`）。
- `prefix`: `NSUbiquitousKeyValueStore` 键的前缀。
- `observeFirst`: 观察优先级模式（默认为 `false`）。
- `syncImmediately`: 是否强制立即同步（默认为 `false`）。
- `developmentMode`: 是否使用内存存储进行测试（默认为 `false`）。
- `defaultIsolationIsMainActor`: 目标是否以 MainActor 作为默认隔离（默认为 `false`）。

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

### 属性观察器（`willSet` / `didSet`）

- `@DefaultsBacked` 和 `@CloudBacked` 不支持 `willSet` / `didSet`。
- `@ObservableOnly` 支持 `willSet` / `didSet`。
- 在观察优先模式中，被自动标记为 `@ObservableOnly` 的属性同样支持 `willSet` / `didSet`。

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

struct People: Codable {
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

struct UserProfile: Codable {
    var name: String
    var preferences: UserPreferences
}

struct UserPreferences: Codable {
    var theme: String = "light"
    var fontSize: Int = 14
}
```

### Enum RawRepresentable 支持

当枚举的 `RawValue` 本身就是属性列表支持的类型（例如 `String`、`Int` 等）时，宏会自动通过 rawValue 进行持久化：

```swift
enum Theme: String {
    case light
    case dark
    case system
}

@ObservableDefaults
class AppearanceSettings {
    var theme: Theme = Theme.system
}
```

当类型同时遵循 `RawRepresentable` 和 `Codable` 时，库会优先使用 `RawRepresentable` 的存储方式，通过原始值（raw value）存储数据，而不是使用 JSON 编码。这确保了与现有数据的向后兼容性，并为枚举类型提供了更高效的存储方式。

### 存储决策规则（直接访问 Key 时请务必遵循）

以下规则同时适用于 `@ObservableDefaults`（`UserDefaults`）和 `@ObservableCloud`（`NSUbiquitousKeyValueStore`）。
当类型同时满足多个约束时，按“越具体越优先”的顺序选择：

1. `RawRepresentable & PropertyListValue & Codable`
2. `RawRepresentable & PropertyListValue`
3. `RawRepresentable`（且 `RawValue` 为 PropertyList 可存储类型）
4. `PropertyListValue & Codable`
5. `PropertyListValue`
6. 仅 `Codable`（JSON `Data` 路径，优先级最低）

#### 各组合的实际存储格式

- `RawRepresentable` 路径：保存 `rawValue`。
  - 例如 `String`/`Int` rawValue 会直接以 `String`/`Int` 存储。
- `PropertyListValue` 路径：直接以 PropertyList 值存储。
- 仅 `Codable` 路径：以 JSON 编码后的 `Data` 存储。
- `URL` / `NSURL` 路径：使用 `URL` 的 Codable 表示并以 JSON 编码后的
  `Data` 存储，不会把 URL 对象直接作为 PropertyList 值写入
  `UserDefaults` 或 `NSUbiquitousKeyValueStore`。
- Optional 值：
  - 非 `nil`：按上述规则保存
  - `nil`：删除对应 key

#### 读取回退（兼容历史数据）

对于 `RawRepresentable & PropertyListValue`（包括 `RawRepresentable & PropertyListValue & Codable`）：

- 读取时先按 `rawValue` 格式解析。
- 若失败，再回退到直接 `PropertyListValue` 转换。

这保证了历史上“按 PropertyList 直接写入”的旧数据，在后来属性演进为 `RawRepresentable` 后仍可读取。

#### 与手动读写保持一致

如果你在其他位置直接读写 `UserDefaults` / iCloud key，请使用同样的格式规则：

- `RawRepresentable` 相关属性：手动写 `rawValue`
- `PropertyListValue` 属性：手动写 PropertyList 原值
- 仅 `Codable` 属性：手动写 JSON `Data`
- `URL` / `NSURL` 属性：手动写由 `URL` 编码得到的 JSON `Data`
- key 规则与宏一致：
  - 默认：`prefix + propertyName`
  - 自定义 key：`@DefaultsKey` / `@CloudKey`

示例（`UserDefaults`）：

```swift
// RawRepresentable 属性（rawValue: String）
defaults.set(theme.rawValue, forKey: "app_theme")

// 仅 Codable 属性
defaults.set(try JSONEncoder().encode(profile), forKey: "app_profile")

// URL / NSURL 属性
defaults.set(try JSONEncoder().encode(homepageURL), forKey: "app_homepage")
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
