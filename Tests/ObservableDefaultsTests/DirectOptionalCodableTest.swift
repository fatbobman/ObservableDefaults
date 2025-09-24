import Foundation
import ObservableDefaults
import Testing

// Test the original issue directly
struct DirectUser: Codable, Equatable {
    var name: String
    var age: Int
}

@ObservableDefaults
class SettingsWithOptionalUser {
    var user: DirectUser? = nil  // This should work now with PR #11 solution
}

@Test("Demonstrate UserDefaults optional Codable works")
func testUserDefaultsOptionalCodableWorks() async throws {
    // Clean UserDefaults
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "user")
    
    let settings = SettingsWithOptionalUser()
    
    // Initial nil should work
    #expect(settings.user == nil)
    
    // This assignment should work without crash
    let testUser = DirectUser(name: "John", age: 30)
    
    print("About to assign DirectUser? - this should work now...")
    
    // This should work with the PR #11 solution
    settings.user = testUser
    
    print("Assignment completed successfully!")
    print("User value: \(String(describing: settings.user))")
    
    // Verify it works
    #expect(settings.user?.name == "John")
    #expect(settings.user?.age == 30)
    
    // Test setting back to nil
    settings.user = nil
    #expect(settings.user == nil)
    
    print("✅ Optional Codable types work perfectly with native Swift syntax!")
}
