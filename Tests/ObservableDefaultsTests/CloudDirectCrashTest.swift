import Foundation
import ObservableDefaults
import Testing

// Test structures
struct CloudCrashUser: Codable, CodableCloudPropertyListValue, Equatable {
    var name: String
    var age: Int
}

// Test optional Codable types with real iCloud store
@ObservableCloud(developmentMode: false)  // Use real iCloud store to test
class CloudSettingsWithOptionalCrashUser {
    var user: CloudCrashUser? = nil  // This should work now with our solution
}

@Test("Test if ObservableCloud works with optional Codable types using real iCloud")
func testObservableCloudOptionalCodableWorksWithRealICloud() async throws {
    let settings = CloudSettingsWithOptionalCrashUser()
    
    // Initial nil should work
    #expect(settings.user == nil)
    
    // This assignment should work without issues
    let testUser = CloudCrashUser(name: "John", age: 30)
    
    print("About to assign CloudCrashUser? to @ObservableCloud...")
    
    // Test assignment - this should work with our solution
    settings.user = testUser
    
    print("Assignment completed successfully!")
    print("User value: \(String(describing: settings.user))")
    
    // Verify it works
    #expect(settings.user?.name == "John")
    #expect(settings.user?.age == 30)
    
    // Try to read it back
    let retrievedUser = settings.user
    print("Retrieved user: \(String(describing: retrievedUser))")
    
    // Test setting to nil
    settings.user = nil
    #expect(settings.user == nil)
    
    print("✅ Optional Codable types work with real ObservableCloud!")
}