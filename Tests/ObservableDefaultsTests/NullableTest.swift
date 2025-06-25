import Foundation
import ObservableDefaults
import Testing

// Test structures
struct User: Codable, CodableUserDefaultsPropertyListValue {
    var name: String
    var age: Int
}

struct UserPreferences: Codable, CodableUserDefaultsPropertyListValue {
    var theme: String
    var notifications: Bool
}

@ObservableDefaults
class SettingsWithNullable {
    var currentUser: Nullable<User> = Nullable.none
    var preferences: Nullable<UserPreferences> = nil  // Using ExpressibleByNilLiteral
}

@Test("Nullable should work with ObservableDefaults")
func testNullableWithObservableDefaults() async throws {
    // Clean UserDefaults
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "currentUser")
    userDefaults.removeObject(forKey: "preferences")
    
    let settings = SettingsWithNullable()
    
    // Test initial nil values
    #expect(settings.currentUser.value == nil)
    #expect(settings.preferences.value == nil)
    #expect(!settings.currentUser.hasValue)
    #expect(!settings.preferences.hasValue)
    
    // Test setting values
    let user = User(name: "John Doe", age: 30)
    settings.currentUser = Nullable.from(value: user)
    
    let prefs = UserPreferences(theme: "dark", notifications: true)
    settings.preferences = Nullable.some(prefs)
    
    // Verify values are set correctly
    #expect(settings.currentUser.value?.name == "John Doe")
    #expect(settings.currentUser.value?.age == 30)
    #expect(settings.preferences.value?.theme == "dark")
    #expect(settings.preferences.value?.notifications == true)
    #expect(settings.currentUser.hasValue)
    #expect(settings.preferences.hasValue)
    
    // Test setting back to nil
    settings.currentUser = Nullable.none
    settings.preferences = nil
    
    #expect(settings.currentUser.value == nil)
    #expect(settings.preferences.value == nil)
    #expect(!settings.currentUser.hasValue)
    #expect(!settings.preferences.hasValue)
}

@Test("Nullable helper methods should work correctly")
func testNullableHelperMethods() async throws {
    // Test from(value:) with nil
    let nilUser: User? = nil
    let nullableFromNil = Nullable.from(value: nilUser)
    #expect(nullableFromNil.value == nil)
    #expect(!nullableFromNil.hasValue)
    
    // Test from(value:) with value
    let user = User(name: "Alice", age: 25)
    let nullableFromValue = Nullable.from(value: user)
    #expect(nullableFromValue.value?.name == "Alice")
    #expect(nullableFromValue.hasValue)
    
    // Test valueOrDefault
    let defaultUser = User(name: "Default", age: 0)
    #expect(nullableFromNil.valueOrDefault(defaultUser).name == "Default")
    #expect(nullableFromValue.valueOrDefault(defaultUser).name == "Alice")
    
    // Test map
    let mappedNames = nullableFromValue.map { $0.name }
    #expect(mappedNames.value == "Alice")
    
    let mappedNil = nullableFromNil.map { $0.name }
    #expect(mappedNil.value == nil)
}

@Test("Nullable should support pattern matching")
func testNullablePatternMatching() async throws {
    let user = User(name: "Bob", age: 35)
    let someNullable = Nullable.some(user)
    let noneNullable: Nullable<User> = Nullable.none
    
    // Test pattern matching
    switch someNullable {
    case .none:
        #expect(Bool(false), "Should not be none")
    case .some(let value):
        #expect(value.name == "Bob")
    }
    
    switch noneNullable {
    case .none:
        #expect(Bool(true), "Should be none")
    case .some:
        #expect(Bool(false), "Should not have value")
    }
}

@Test("Nullable should be Equatable")
func testNullableEquatable() async throws {
    let user1 = User(name: "Charlie", age: 40)
    let user2 = User(name: "Charlie", age: 40)
    let user3 = User(name: "David", age: 30)
    
    let nullable1 = Nullable.some(user1)
    let nullable2 = Nullable.some(user2)
    let nullable3 = Nullable.some(user3)
    let nullable4: Nullable<User> = Nullable.none
    let nullable5: Nullable<User> = Nullable.none
    
    #expect(nullable1 == nullable2)  // Same values
    #expect(nullable1 != nullable3)  // Different values
    #expect(nullable4 == nullable5)  // Both none
    #expect(nullable1 != nullable4)  // Some vs none
}