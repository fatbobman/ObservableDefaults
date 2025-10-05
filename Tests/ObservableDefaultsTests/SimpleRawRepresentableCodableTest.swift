import Foundation
import ObservableDefaults
import Testing

// Minimal test to verify compilation works
private struct TestType: RawRepresentable, Codable, Equatable {
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

@ObservableDefaults(prefix: "SimpleTest_")
private class SimpleStore {
    var test = TestType(value: "default")
}

@Suite("Simple RawRepresentable & Codable Test")
struct SimpleRawRepresentableCodableTest {
    @Test
    func verifyCompilation() {
        // Clean up UserDefaults before test
        UserDefaults.standard.removeObject(forKey: "SimpleTest_test")

        let store = SimpleStore()
        store.test = TestType(value: "updated")
        #expect(store.test.value == "updated")
    }
}
