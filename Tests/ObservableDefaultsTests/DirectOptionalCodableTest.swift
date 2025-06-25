import Foundation
import ObservableDefaults
import Testing

// Test the original issue directly
struct DirectUser: Codable, CodableUserDefaultsPropertyListValue, Equatable {
    var name: String
    var age: Int
}

@ObservableDefaults
class SettingsWithOptionalUser {
    var user: DirectUser? = nil  // This should crash
}

@ObservableDefaults  
class SettingsWithNullableUser {
    var user: Nullable<DirectUser> = Nullable.none  // This should work
}

@Test("Demonstrate UserDefaults optional Codable crash")
func testUserDefaultsOptionalCodableCrash() async throws {
    // Clean UserDefaults
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "user")
    
    let settings = SettingsWithOptionalUser()
    
    // Initial nil should work
    #expect(settings.user == nil)
    
    // This assignment should trigger the crash
    let testUser = DirectUser(name: "John", age: 30)
    
    print("About to assign DirectUser? - this may crash...")
    
    // This is where the "Attempt to insert non-property list object" crash should occur
    settings.user = testUser
    
    print("Assignment completed without crash - unexpected!")
    print("User value: \(String(describing: settings.user))")
}

@Test("Demonstrate Nullable solution works for UserDefaults")
func testNullableSolutionForUserDefaults() async throws {
    // Clean UserDefaults  
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "user")
    
    let settings = SettingsWithNullableUser()
    
    // Initial nil should work
    #expect(settings.user.value == nil)
    
    // This assignment should work fine
    let testUser = DirectUser(name: "Alice", age: 25)
    settings.user = Nullable.from(value: testUser)
    
    // Verify it works
    #expect(settings.user.value?.name == "Alice")
    #expect(settings.user.value?.age == 25)
    #expect(settings.user.hasValue)
    
    // Test setting to nil
    settings.user = Nullable.none
    #expect(settings.user.value == nil)
    #expect(!settings.user.hasValue)
    
    print("✅ Nullable solution works perfectly for UserDefaults!")
}