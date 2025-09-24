//
// CloudPropertyListValue.swift
// Created by Xu Yang on 2025-05-23.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

/// Protocol for types that can be stored in NSUbiquitousKeyValueStore
public protocol CloudPropertyListValue {}

/// Compatibility shim: legacy projects may still conform to this typealias.
///
/// New code can simply conform to `Codable`—this remains only to avoid breaking
/// existing code and may be removed in a future major release.
public typealias CodableCloudPropertyListValue = Codable

// Extensions for basic types supported by NSUbiquitousKeyValueStore
extension String: CloudPropertyListValue {}
extension Int: CloudPropertyListValue {}
extension Int64: CloudPropertyListValue {}
extension Double: CloudPropertyListValue {}
extension Float: CloudPropertyListValue {}
extension Bool: CloudPropertyListValue {}
extension Data: CloudPropertyListValue {}
extension Date: CloudPropertyListValue {}

// Collections
extension Array: CloudPropertyListValue where Element: CloudPropertyListValue {}
extension Dictionary: CloudPropertyListValue where Key == String, Value: CloudPropertyListValue {}

// Optional types
extension Optional: CloudPropertyListValue where Wrapped: CloudPropertyListValue {}
