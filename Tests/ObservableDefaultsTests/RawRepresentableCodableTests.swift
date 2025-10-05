import Foundation
import ObservableDefaults
import Testing

// Test type that conforms to both RawRepresentable and Codable
// This simulates the user's scenario from issue #23
private struct UserProfile: RawRepresentable, Equatable {
    var name: String
    var age: Int

    // RawRepresentable conformance using JSON string
    var rawValue: String {
        // Manually construct JSON to avoid Codable encoding
        return "{\"name\": \"\(name)\", \"age\": \(age)}"
    }

    init?(rawValue: String) {
        // Simple JSON parsing for test purposes
        guard let data = rawValue.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let age = json["age"] as? Int else {
            return nil
        }
        self.name = name
        self.age = age
    }

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

// Make it Codable for testing the conflict scenario
extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case age
    }
}

// Optional version test
private enum Status: String, Codable {
    case active
    case inactive
}

@ObservableDefaults(prefix: "Test1_")
private class TestStore1 {
    var profile = UserProfile(name: "Default", age: 0)
}

@ObservableDefaults(prefix: "Test2_")
private class TestStore2 {
    var profile = UserProfile(name: "Default", age: 0)
}

@ObservableDefaults(prefix: "Test3_")
private class TestStore3 {
    var optionalProfile: UserProfile?
}

@ObservableDefaults(prefix: "Test4_")
private class TestStore4 {
    var status = Status.active
}

@ObservableCloud(prefix: "CloudTest1_", developmentMode: true)
private class CloudTestStore1 {
    var profile = UserProfile(name: "Default", age: 0)
}

@ObservableCloud(prefix: "CloudTest2_", developmentMode: true)
private class CloudTestStore2 {
    var profile = UserProfile(name: "Default", age: 0)
}

@ObservableCloud(prefix: "CloudTest3_", developmentMode: true)
private class CloudTestStore3 {
    var optionalProfile: UserProfile?
}

@ObservableCloud(prefix: "CloudTest4_", developmentMode: true)
private class CloudTestStore4 {
    var status = Status.active
}

@Suite("RawRepresentable & Codable Conflict Tests")
struct RawRepresentableCodableTests {

    @Test("Type conforming to both RawRepresentable and Codable should compile")
    func compilationTest() {
        // This test verifies that the code compiles without ambiguity errors
        let store = TestStore1()
        #expect(store.profile.name == "Default")
        #expect(store.profile.age == 0)
    }

    @Test("Should use RawRepresentable storage (not Codable JSON encoding)")
    func storageFormatTest() {
        let store = TestStore2()
        let testProfile = UserProfile(name: "Alice", age: 30)

        store.profile = testProfile

        // Verify the value is stored correctly
        #expect(store.profile.name == "Alice")
        #expect(store.profile.age == 30)

        // Check that it's stored as a String (RawRepresentable way), not as Data (Codable way)
        let userDefaults = UserDefaults.standard
        let storedValue = userDefaults.object(forKey: "Test2_profile")

        // Should be stored as String (raw value), not Data (Codable encoding)
        #expect(storedValue is String)
        #expect(storedValue is Data == false)
    }

    @Test("Should read existing RawRepresentable data correctly")
    func backwardCompatibilityTest() {
        let userDefaults = UserDefaults.standard
        let key = "testProfile"

        // Simulate existing data stored as RawRepresentable (JSON string)
        let existingProfile = UserProfile(name: "Bob", age: 25)
        userDefaults.set(existingProfile.rawValue, forKey: key)

        // Read it back using the wrapper
        let retrieved = UserDefaultsWrapper<UserProfile>.getValue(
            key,
            UserProfile(name: "Default", age: 0),
            userDefaults
        )

        #expect(retrieved.name == "Bob")
        #expect(retrieved.age == 25)

        // Cleanup
        userDefaults.removeObject(forKey: key)
    }

    @Test("Optional RawRepresentable & Codable type should work")
    func optionalTest() {
        let store = TestStore3()

        #expect(store.optionalProfile == nil)

        store.optionalProfile = UserProfile(name: "Charlie", age: 35)
        #expect(store.optionalProfile?.name == "Charlie")
        #expect(store.optionalProfile?.age == 35)

        store.optionalProfile = nil
        #expect(store.optionalProfile == nil)
    }

    @Test("Enum with RawRepresentable and Codable should work")
    func enumTest() {
        // Clean up to ensure fresh state
        UserDefaults.standard.removeObject(forKey: "Test4_status")

        let store = TestStore4()

        #expect(store.status == .active)

        store.status = .inactive
        #expect(store.status == .inactive)

        // Verify it's stored as raw value (String), not encoded Data
        let userDefaults = UserDefaults.standard
        let storedValue = userDefaults.object(forKey: "Test4_status")
        #expect(storedValue is String)
        #expect((storedValue as? String) == "inactive")
    }

    // MARK: - Cloud Tests

    @Test("Cloud: Type conforming to both RawRepresentable and Codable should compile")
    func cloudCompilationTest() {
        let store = CloudTestStore1()
        #expect(store.profile.name == "Default")
        #expect(store.profile.age == 0)
    }

    @Test("Cloud: Should use RawRepresentable storage (not Codable JSON encoding)")
    func cloudStorageFormatTest() {
        let store = CloudTestStore2()
        let testProfile = UserProfile(name: "Alice", age: 30)

        store.profile = testProfile

        #expect(store.profile.name == "Alice")
        #expect(store.profile.age == 30)
    }

    @Test("Cloud: Optional RawRepresentable & Codable type should work")
    func cloudOptionalTest() {
        let store = CloudTestStore3()

        #expect(store.optionalProfile == nil)

        store.optionalProfile = UserProfile(name: "Charlie", age: 35)
        #expect(store.optionalProfile?.name == "Charlie")
        #expect(store.optionalProfile?.age == 35)

        store.optionalProfile = nil
        #expect(store.optionalProfile == nil)
    }

    @Test("Cloud: Enum with RawRepresentable and Codable should work")
    func cloudEnumTest() {
        let store = CloudTestStore4()

        #expect(store.status == .active)

        store.status = .inactive
        #expect(store.status == .inactive)
    }
}
