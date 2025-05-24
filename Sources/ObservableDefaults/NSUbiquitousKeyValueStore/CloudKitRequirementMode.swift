//
// CloudKitRequirementMode.swift
// Created by Xu Yang on 2025-05-24.
// Blog: https://fatbobman.com
// GitHub: https://github.com/fatbobman
//
// Copyright © 2025 Fatbobman. All rights reserved.

import Foundation

/// Defines how the app handles CloudKit configuration requirements
public enum CloudKitRequirementMode {
    /// Safe mode: Gracefully handles missing CloudKit configuration
    ///
    /// Falls back to in-memory storage when CloudKit container is unavailable
    case development

    /// Strict mode: Requires proper CloudKit configuration
    ///
    /// Application crashes if CloudKit container is not configured (production safety)
    case production
}
