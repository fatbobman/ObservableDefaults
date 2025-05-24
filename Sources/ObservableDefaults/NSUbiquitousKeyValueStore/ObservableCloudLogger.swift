//
// ObservableCloudLogger.swift
// Created by Xu Yang on 2025-05-24.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

/// Protocol for logging messages related to NSUbiquitousKeyValueStore operations
public protocol ObservableCloudLogger {
    /// Logs a message with the specified level
    ///
    /// - Parameters:
    ///   - level: The log level (e.g., debug, info, error)
    ///   - message: The message to log
    func log(_ message: String)
}
