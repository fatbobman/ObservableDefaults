import Foundation
import ObservableDefaults
import Testing

private struct UserProfile: RawRepresentable, Codable, Equatable {
    var name: String
    var age: Int

    var rawValue: String {
        "\(name)|\(age)"
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, let age = Int(parts[1]) else { return nil }
        self.name = parts[0]
        self.age = age
    }

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

private struct RawStringToken: RawRepresentable, Equatable {
    var value: String

    var rawValue: String {
        value
    }

    init?(rawValue: String) {
        self.value = rawValue
    }

    init(value: String) {
        self.value = value
    }
}

private struct HybridStringToken: RawRepresentable, Codable, Equatable {
    var value: String

    var rawValue: String {
        value
    }

    init?(rawValue: String) {
        self.value = rawValue
    }

    init(value: String) {
        self.value = value
    }
}

private struct HybridIntToken: RawRepresentable, Codable, Equatable {
    var value: Int

    var rawValue: Int {
        value
    }

    init?(rawValue: Int) {
        self.value = rawValue
    }

    init(value: Int) {
        self.value = value
    }
}

extension RawStringToken: UserDefaultsPropertyListValue {}
extension RawStringToken: CloudPropertyListValue {}
extension HybridStringToken: UserDefaultsPropertyListValue {}
extension HybridStringToken: CloudPropertyListValue {}
extension HybridIntToken: UserDefaultsPropertyListValue {}
extension HybridIntToken: CloudPropertyListValue {}

private enum Status: String, Codable {
    case active
    case inactive
}

@ObservableDefaults(prefix: "RRC_defaults_rawCodable_")
private class DefaultsRawCodableStore {
    var profile = UserProfile(name: "Default", age: 0)
}

@ObservableDefaults(prefix: "RRC_defaults_rawProperty_")
private class DefaultsRawPropertyStore {
    var token = RawStringToken(value: "default")
    var optionalToken: RawStringToken?
}

@ObservableDefaults(prefix: "RRC_defaults_hybrid_")
private class DefaultsHybridStore {
    var hybrid = HybridIntToken(value: 1)
    var optionalHybrid: HybridIntToken?
}

@ObservableDefaults(prefix: "RRC_defaults_enum_")
private class DefaultsEnumStore {
    var status = Status.active
}

@ObservableDefaults(prefix: "RRC_defaults_compat_")
private class DefaultsLegacyPropertyListStore {
    var value = "legacy"
}

@ObservableDefaults(prefix: "RRC_defaults_compat_")
private class DefaultsMigratedHybridStore {
    var value = HybridStringToken(value: "default")
}

@ObservableCloud(prefix: "RRC_cloud_rawCodable_")
private class CloudRawCodableStore {
    var profile = UserProfile(name: "Default", age: 0)
}

@ObservableCloud(prefix: "RRC_cloud_rawProperty_")
private class CloudRawPropertyStore {
    var token = RawStringToken(value: "default")
    var optionalToken: RawStringToken?
}

@ObservableCloud(prefix: "RRC_cloud_hybrid_")
private class CloudHybridStore {
    var hybrid = HybridIntToken(value: 1)
    var optionalHybrid: HybridIntToken?
}

@ObservableCloud(prefix: "RRC_cloud_enum_")
private class CloudEnumStore {
    var status = Status.active
}

@Suite("RawRepresentable & Codable Tests", .serialized)
struct RawRepresentableCodableTests {
    @Test("Defaults: RawRepresentable + Codable uses raw-value storage")
    func defaultsRawCodableStorage() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsRawCodableStore(userDefaults: userDefaults)

        store.profile = UserProfile(name: "Alice", age: 30)
        #expect(store.profile == UserProfile(name: "Alice", age: 30))

        let stored = userDefaults.object(forKey: "RRC_defaults_rawCodable_profile")
        #expect(stored as? String == "Alice|30")
        #expect(stored is Data == false)
    }

    @Test("Defaults: RawRepresentable + PropertyList (with optional) works")
    func defaultsRawPropertyListOnly() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsRawPropertyStore(userDefaults: userDefaults)

        store.token = RawStringToken(value: "updated")
        #expect(store.token == RawStringToken(value: "updated"))
        #expect(userDefaults.object(forKey: "RRC_defaults_rawProperty_token") as? String == "updated")

        store.optionalToken = RawStringToken(value: "optional")
        #expect(store.optionalToken == RawStringToken(value: "optional"))
        #expect(userDefaults.object(forKey: "RRC_defaults_rawProperty_optionalToken") as? String == "optional")

        store.optionalToken = nil
        #expect(store.optionalToken == nil)
        #expect(userDefaults.object(forKey: "RRC_defaults_rawProperty_optionalToken") == nil)
    }

    @Test("Defaults: RawRepresentable + PropertyList + Codable uses raw-value storage")
    func defaultsRawPropertyListCodable() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsHybridStore(userDefaults: userDefaults)

        store.hybrid = HybridIntToken(value: 42)
        #expect(store.hybrid == HybridIntToken(value: 42))
        let stored = userDefaults.object(forKey: "RRC_defaults_hybrid_hybrid")
        #expect(stored as? Int == 42)
        #expect(stored is Data == false)

        store.optionalHybrid = HybridIntToken(value: 7)
        #expect(store.optionalHybrid == HybridIntToken(value: 7))
        #expect(userDefaults.object(forKey: "RRC_defaults_hybrid_optionalHybrid") as? Int == 7)

        store.optionalHybrid = nil
        #expect(store.optionalHybrid == nil)
        #expect(userDefaults.object(forKey: "RRC_defaults_hybrid_optionalHybrid") == nil)
    }

    @Test("Defaults: RawRepresentable enum + Codable works")
    func defaultsEnumRawRepresentableCodable() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsEnumStore(userDefaults: userDefaults)

        store.status = .inactive
        #expect(store.status == .inactive)
        #expect(userDefaults.object(forKey: "RRC_defaults_enum_status") as? String == "inactive")
    }

    @Test("Defaults compatibility: legacy PropertyList data remains readable after adding RawRepresentable")
    func defaultsPropertyListMigrationCompatibility() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)

        let legacyStore = DefaultsLegacyPropertyListStore(userDefaults: userDefaults)
        legacyStore.value = "legacy-v1"
        #expect(userDefaults.object(forKey: "RRC_defaults_compat_value") as? String == "legacy-v1")

        let migratedStore = DefaultsMigratedHybridStore(userDefaults: userDefaults)
        #expect(migratedStore.value == HybridStringToken(value: "legacy-v1"))

        migratedStore.value = HybridStringToken(value: "legacy-v2")
        #expect(userDefaults.object(forKey: "RRC_defaults_compat_value") as? String == "legacy-v2")
    }

    @Test("Cloud: RawRepresentable + Codable works")
    func cloudRawCodableStorage() {
        let store = CloudRawCodableStore(developmentMode: true)

        store.profile = UserProfile(name: "Alice", age: 30)
        #expect(store.profile == UserProfile(name: "Alice", age: 30))
    }

    @Test("Cloud: RawRepresentable + PropertyList (with optional) works")
    func cloudRawPropertyListOnly() {
        let store = CloudRawPropertyStore(developmentMode: true)

        store.token = RawStringToken(value: "updated")
        #expect(store.token == RawStringToken(value: "updated"))

        store.optionalToken = RawStringToken(value: "optional")
        #expect(store.optionalToken == RawStringToken(value: "optional"))

        store.optionalToken = nil
        #expect(store.optionalToken == nil)
    }

    @Test("Cloud: RawRepresentable + PropertyList + Codable works")
    func cloudRawPropertyListCodable() {
        let store = CloudHybridStore(developmentMode: true)

        store.hybrid = HybridIntToken(value: 42)
        #expect(store.hybrid == HybridIntToken(value: 42))

        store.optionalHybrid = HybridIntToken(value: 7)
        #expect(store.optionalHybrid == HybridIntToken(value: 7))

        store.optionalHybrid = nil
        #expect(store.optionalHybrid == nil)
    }

    @Test("Cloud: RawRepresentable enum + Codable works")
    func cloudEnumRawRepresentableCodable() {
        let store = CloudEnumStore(developmentMode: true)

        store.status = .inactive
        #expect(store.status == .inactive)
    }
}
