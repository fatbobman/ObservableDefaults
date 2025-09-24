import Foundation
import ObservableDefaults
import Testing

private struct LegacyDefaultsValue: CodableUserDefaultsPropertyListValue, Equatable {
    var text: String = "legacy"
}

private struct LegacyCloudValue: CodableCloudPropertyListValue, Equatable {
    var text: String = "legacy"
}

@ObservableDefaults
private class LegacyDefaultsStore {
    var value = LegacyDefaultsValue()
}

@ObservableCloud(developmentMode: true)
private class LegacyCloudStore {
    var value = LegacyCloudValue()
}

@Suite("Compatibility Tests")
struct CompatibilityTests {
    @Test
    func defaultsCodableCompatibility() {
        let store = LegacyDefaultsStore()
        store.value = LegacyDefaultsValue(text: "updated")
        #expect(store.value.text == "updated")
    }

    @Test
    func cloudCodableCompatibility() {
        let store = LegacyCloudStore()
        store.value = LegacyCloudValue(text: "updated")
        #expect(store.value.text == "updated")
    }
}
