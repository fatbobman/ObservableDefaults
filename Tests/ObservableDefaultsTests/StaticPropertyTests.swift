//
//  Test case for static property issue #19
//  https://github.com/fatbobman/ObservableDefaults/issues/19
//

import Foundation
@testable import ObservableDefaults
import Testing

// Test case 1: ObservableDefaults with static property
@MainActor
@ObservableDefaults
class ExampleWithStatic {
    public var foo = 1
    public static var shared = ExampleWithStatic()
}

// Test case 2: ObservableDefaults with multiple static properties
@MainActor
@ObservableDefaults
class ModelWithMultipleStatics {
    var name = "Test"
    var age = 18

    static let defaultName = "Default"
    static var currentCount = 0
    private static var privateStatic = 42
}

// Test case 3: ObservableCloud with static property
@MainActor
@ObservableCloud
class CloudModelWithStatic {
    var cloudData = "Cloud"
    static var sharedInstance = CloudModelWithStatic()

    @Ignore
    var setResult: [String] = []
}

// Test case 4: Static computed properties
@MainActor
@ObservableDefaults
class ModelWithStaticComputed {
    var value = 100

    static var defaultValue: Int {
        return 100
    }

    static var shared: ModelWithStaticComputed {
        return ModelWithStaticComputed()
    }
}

// Test case 5: ObservableCloud with static and instance properties
@MainActor
@ObservableCloud(observeFirst: true)
class CloudModelMixed {
    @CloudBacked
    var name = "Test"

    var observableOnly = "Observable"

    static let constants = "Constants"
    static var sharedModel = CloudModelMixed()

    @Ignore
    var ignored = "Ignored"
}

@Suite("Static Property Tests")
struct StaticPropertyTests {
    @Test("ObservableDefaults with static property should compile")
    @MainActor
    func testStaticProperty() {
        let instance = ExampleWithStatic.shared
        instance.foo = 2
        #expect(instance.foo == 2)
    }

    @MainActor
    @Test("ObservableDefaults with multiple static properties")
    func testMultipleStaticProperties() {
        let instance = ModelWithMultipleStatics()
        instance.name = "Updated"
        instance.age = 25

        #expect(instance.name == "Updated")
        #expect(instance.age == 25)
        #expect(ModelWithMultipleStatics.defaultName == "Default")
        #expect(ModelWithMultipleStatics.currentCount == 0)
    }

    @MainActor
    @Test("ObservableCloud with static property in development mode")
    func testCloudWithStatic() {
        UserDefaults.clearMock()
        let instance = CloudModelWithStatic(developmentMode: true)
        instance.cloudData = "Updated Cloud"
        #expect(instance.cloudData == "Updated Cloud")

        let shared = CloudModelWithStatic.sharedInstance
        #expect(shared.cloudData == "Cloud")
    }

    @MainActor
    @Test("ObservableCloud with mixed static and instance properties")
    func testCloudMixedProperties() {
        UserDefaults.clearMock()
        let instance = CloudModelMixed(developmentMode: true)
        instance.name = "Updated"
        instance.observableOnly = "Changed"

        #expect(instance.name == "Updated")
        #expect(instance.observableOnly == "Changed")
        #expect(CloudModelMixed.constants == "Constants")

        // Static properties should not interfere with instance properties
        let shared = CloudModelMixed.sharedModel
        #expect(shared.name == "Test")
    }
}
