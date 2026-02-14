import Foundation
import ObservableDefaults
import Testing

private struct HybridValue: RawRepresentable, Codable, Equatable {
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

extension HybridValue: UserDefaultsPropertyListValue {}
extension HybridValue: CloudPropertyListValue {}

@ObservableDefaults(prefix: "Issue26_defaults_")
private class Issue26DefaultsStore {
    var value = HybridValue(value: "default")
}

@ObservableCloud(prefix: "Issue26_cloud_")
private class Issue26CloudStore {
    var value = HybridValue(value: "default")
}

@Suite("Issue26 Overload Ambiguity Tests", .serialized)
struct Issue26OverloadAmbiguityTests {
    @Test("UserDefaults: hybrid type compiles and uses RawRepresentable storage")
    func defaultsHybridType() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = Issue26DefaultsStore(userDefaults: userDefaults)

        store.value = HybridValue(value: "updated")
        #expect(store.value == HybridValue(value: "updated"))

        let stored = userDefaults.object(forKey: "Issue26_defaults_value")
        #expect(stored as? String == "updated")
        #expect(stored is Data == false)
    }
}

#if swift(>=6.1)
    extension Issue26OverloadAmbiguityTests {
        @Test("Cloud: hybrid type compiles and uses RawRepresentable storage", .testMode)
        func cloudHybridType() {
            UserDefaults.clearMock()
            let store = Issue26CloudStore(developmentMode: false)

            store.value = HybridValue(value: "updated")
            #expect(store.value == HybridValue(value: "updated"))

            let stored = UserDefaults.mock.object(forKey: "Issue26_cloud_value")
            #expect(stored as? String == "updated")
            #expect(stored is Data == false)
        }
    }
#endif
