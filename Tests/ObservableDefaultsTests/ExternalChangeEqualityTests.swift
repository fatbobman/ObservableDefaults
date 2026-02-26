//
//  ExternalChangeEqualityTests.swift
//  ObservableDefaults
//
//  Tests that the external UserDefaults change notification handler
//  only triggers observation mutations when values actually change.
//

import Foundation
import ObservableDefaults
import Observation
import Testing

@Suite("External Change Equality Check")
struct ExternalChangeEqualityTests {

    @Test("Unrelated property not notified when another property changes externally")
    func unrelatedPropertyNotNotified() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let model = MockModel(userDefaults: userDefaults)

        // Track age - expect NO mutation when only name changes
        tracking(model, \.age, .userDefaults, false)
        userDefaults.set("NewName", forKey: "name")
    }
}
