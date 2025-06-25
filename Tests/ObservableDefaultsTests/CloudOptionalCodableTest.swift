import Foundation
import ObservableDefaults
import Testing

// Test structures for Cloud
struct CloudUser: Codable, CodableCloudPropertyListValue, Equatable {
    var name: String
    var age: Int
}

struct CloudImage: Codable, CodableCloudPropertyListValue, Equatable {
    var raw: Data
}

struct CloudUserWithImage: Codable, CodableCloudPropertyListValue, Equatable {
    var name: String
    var image: CloudImage
}

// Test the issue: Optional Codable types with @ObservableCloud
@ObservableCloud(developmentMode: true)  // Use development mode for testing
class CloudSettingsWithOptionalCodable {
    var optionalUser: CloudUser? = nil  // This should crash like UserDefaults
}

// Test the solution: Using Nullable<T> with @ObservableCloud
@ObservableCloud(developmentMode: true)
class CloudSettingsWithNullable {
    var user: Nullable<CloudUser> = Nullable.none
    var userWithImage: Nullable<CloudUserWithImage> = nil  // Using nil literal
}

@Test("ObservableCloud optional Codable types assignment behavior")
func testObservableCloudOptionalCodableIssue() async throws {
    let settings = CloudSettingsWithOptionalCodable()
    
    // Test initial nil value - this should work
    #expect(settings.optionalUser == nil)
    
    // Create a test user
    let testUser = CloudUser(name: "John", age: 30)
    
    // Test assignment - this might not crash but could have other issues
    settings.optionalUser = testUser
    
    // In development mode, values might not persist correctly
    // The main issue is method selection, not necessarily a crash
    print("Assigned CloudUser to optionalUser property")
    print("Current value: \(String(describing: settings.optionalUser))")
    
    // Try setting back to nil
    settings.optionalUser = nil
    print("Set optionalUser to nil")
    print("Current value: \(String(describing: settings.optionalUser))")
}

@Test("Nullable<T> assignment behavior with ObservableCloud")
func testNullableWithObservableCloud() async throws {
    let settings = CloudSettingsWithNullable()
    
    // Test initial nil values
    #expect(settings.user.value == nil)
    #expect(settings.userWithImage.value == nil)
    #expect(!settings.user.hasValue)
    #expect(!settings.userWithImage.hasValue)
    
    // Test setting values
    let user = CloudUser(name: "Alice", age: 25)
    settings.user = Nullable.from(value: user)
    
    let imageData = Data("cloud test image".utf8)
    let image = CloudImage(raw: imageData)
    let userWithImage = CloudUserWithImage(name: "Bob", image: image)
    settings.userWithImage = Nullable.some(userWithImage)
    
    print("Nullable assignment test:")
    print("User: \(settings.user)")
    print("UserWithImage: \(settings.userWithImage)")
    
    // Test setting back to nil
    settings.user = Nullable.none
    settings.userWithImage = nil
    
    print("After setting to nil:")
    print("User: \(settings.user)")
    print("UserWithImage: \(settings.userWithImage)")
}

@Test("Basic demonstration that Nullable works for Cloud")
func testNullableConformsToCodableCloudPropertyListValue() async throws {
    // This test just verifies that Nullable conforms to the right protocols
    let user = CloudUser(name: "Test", age: 30)
    let nullable: Nullable<CloudUser> = Nullable.from(value: user)
    
    // Verify protocol conformance (compile-time check)
    let _: CodableCloudPropertyListValue = nullable
    
    #expect(nullable.value?.name == "Test")
    #expect(nullable.hasValue)
    
    let nilNullable: Nullable<CloudUser> = Nullable.none
    #expect(nilNullable.value == nil)
    #expect(!nilNullable.hasValue)
}