//
// Tracking.swift
// Created by Xu Yang on 2025-05-30.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation
import Observation
import Testing

func tracking<Model, Value>(
    _ model: Model,
    _ keyPath: KeyPath<Model, Value>,
    _ source: Source,
    _ result: Bool = true,
    sourceLocation: Testing.SourceLocation = #_sourceLocation)
{
    withObservationTracking {
        _ = model[keyPath: keyPath]
    } onChange: {
        switch source {
            case .direct:
                #expect(
                    result,
                    "name should \(result ? "" : "not") be observable by setting value directly",
                    sourceLocation: sourceLocation)
            case .userDefaults:
                #expect(
                    result,
                    "name should \(result ? "" : "not") be observable by setting value by UserDefaults",
                    sourceLocation: sourceLocation)
            case .notification:
                #expect(
                    result,
                    "name should \(result ? "" : "not") be observable by setting value by Notification",
                    sourceLocation: sourceLocation)
        }
    }
}

enum Source {
    case direct
    case userDefaults
    case notification
}
