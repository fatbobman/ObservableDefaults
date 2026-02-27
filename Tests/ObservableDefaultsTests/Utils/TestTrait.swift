//
// TestTrait.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
@testable import ObservableDefaults
import Testing

#if swift(>=6.1)
    struct TestModeTrait: TestTrait, SuiteTrait, TestScoping {
        let value: Bool
        func provideScope(
            for test: Test,
            testCase: Test.Case?,
            performing function: @Sendable () async throws -> Void) async throws
        {
            let suiteName = "ObservableDefaults.TestMode.\(UUID().uuidString)"
            try await NSUbiquitousKeyValueStoreWrapper.$isTestEnvironment
                .withValue(value) {
                    try await NSUbiquitousKeyValueStoreWrapper.$testSuiteName
                        .withValue(suiteName) {
                            try await function()
                        }
                }
        }
    }

    extension Trait where Self == TestModeTrait {
        static var testMode: Self {
            TestModeTrait(value: true)
        }
    }
#endif
