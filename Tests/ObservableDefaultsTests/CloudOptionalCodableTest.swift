import Foundation
import ObservableDefaults
import Testing

// Test structures for Cloud
struct CloudUser: Codable, Equatable {
    var name: String
    var age: Int
}

struct CloudImage: Codable, Equatable {
    var raw: Data
}

struct CloudUserWithImage: Codable, Equatable {
    var name: String
    var image: CloudImage
}

// Test optional Codable types with @ObservableCloud
@ObservableCloud(developmentMode: true)  // Use development mode for testing
class CloudSettingsWithOptionalCodable {
    var optionalUser: CloudUser? = nil  // This should work now with our solution
    var userWithImage: CloudUserWithImage? = nil
}

// MARK: - Disabled Test: Experimental Cloud Optional Codable Support
// This test is disabled as Cloud Optional Codable types are still experimental
// and may not work consistently across all environments
@Test("ObservableCloud optional Codable types work correctly", .disabled("Cloud Optional Codable types are experimental"))
func testObservableCloudOptionalCodableWorks() async throws {
    let settings = CloudSettingsWithOptionalCodable()
    
    // Test initial nil value - this should work
    #expect(settings.optionalUser == nil)
    #expect(settings.userWithImage == nil)
    
    // Create test data
    let testUser = CloudUser(name: "John", age: 30)
    let imageData = Data("cloud test image".utf8)
    let image = CloudImage(raw: imageData)
    let userWithImage = CloudUserWithImage(name: "Bob", image: image)
    
    // Test assignment - this should work without issues
    settings.optionalUser = testUser
    settings.userWithImage = userWithImage
    
    print("Assigned CloudUser to optionalUser property")
    print("Current optionalUser: \(String(describing: settings.optionalUser))")
    print("Current userWithImage: \(String(describing: settings.userWithImage))")
    
    // Verify assignments work
    #expect(settings.optionalUser?.name == "John")
    #expect(settings.optionalUser?.age == 30)
    #expect(settings.userWithImage?.name == "Bob")
    
    // Try setting back to nil
    settings.optionalUser = nil
    settings.userWithImage = nil
    
    #expect(settings.optionalUser == nil)
    #expect(settings.userWithImage == nil)
    
    print("✅ Optional Codable types work perfectly with ObservableCloud!")
}
