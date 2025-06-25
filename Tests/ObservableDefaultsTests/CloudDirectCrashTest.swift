import Foundation
import ObservableDefaults
import Testing

// Test structures
struct CloudCrashUser: Codable, CodableCloudPropertyListValue, Equatable {
    var name: String
    var age: Int
}

// Test the issue: Does @ObservableCloud also crash with optional Codable types?
@ObservableCloud(developmentMode: false)  // Use real iCloud store to test the issue
class CloudSettingsWithOptionalCrashUser {
    var user: CloudCrashUser? = nil  // This might crash like UserDefaults
}

@ObservableCloud(developmentMode: false)
class CloudSettingsWithNullableCrashUser {
    var user: Nullable<CloudCrashUser> = Nullable.none  // This should work
}

@Test("Test if ObservableCloud crashes with optional Codable types")
func testObservableCloudOptionalCodableCrash() async throws {
    let settings = CloudSettingsWithOptionalCrashUser()
    
    // Initial nil should work
    #expect(settings.user == nil)
    
    // This assignment might trigger a crash similar to UserDefaults
    let testUser = CloudCrashUser(name: "John", age: 30)
    
    print("About to assign CloudCrashUser? to @ObservableCloud...")
    
    // Test assignment - this might crash or have other issues
    settings.user = testUser
    
    print("Assignment completed!")
    print("User value: \(String(describing: settings.user))")
    
    // Try to read it back
    let retrievedUser = settings.user
    print("Retrieved user: \(String(describing: retrievedUser))")
}

@Test("Test that Nullable works with real iCloud ObservableCloud")  
func testNullableWithRealObservableCloud() async throws {
    let settings = CloudSettingsWithNullableCrashUser()
    
    // Initial nil should work
    #expect(settings.user.value == nil)
    
    // This assignment should work fine
    let testUser = CloudCrashUser(name: "Alice", age: 25)
    settings.user = Nullable.from(value: testUser)
    
    print("Assigned Nullable<CloudCrashUser> successfully")
    print("User: \(settings.user)")
    
    // Verify it works
    #expect(settings.user.value?.name == "Alice")
    #expect(settings.user.value?.age == 25)
    #expect(settings.user.hasValue)
    
    // Test setting to nil
    settings.user = Nullable.none
    #expect(settings.user.value == nil)
    #expect(!settings.user.hasValue)
    
    print("✅ Nullable solution works with real ObservableCloud!")
}