import SwiftSyntax
import SwiftSyntaxBuilder

func makeDefaultsKeyPathMapSyntax(
    className: IdentifierPatternSyntax,
    metas: [PersistedPropertyMeta]
) -> DeclSyntax {
    let keyPathMapLiteral =
        metas.isEmpty
        ? "[:]"
        : "["
            + metas
            .map { "\\\(className).\($0.propertyID): \"\($0.storageKey)\"" }
            .joined(separator: ", ") + "]"

    return
        """
        private let _defaultsKeyPathMap: [PartialKeyPath<\(raw: className)>: String] = \(
            raw: keyPathMapLiteral)
        private var _ignoredKeyPathsForExternalUpdates: [PartialKeyPath<\(raw: className)>] = []
        """
}

func makeMonitoredKeysArrayLiteral(_ metas: [PersistedPropertyMeta]) -> String {
    metas.map { "\"\($0.storageKey)\"" }.joined(separator: ", ")
}

func makeDefaultsObservationCaseCode(
    metas: [PersistedPropertyMeta],
    hasMainActor: Bool
) -> String {
    metas.enumerated().map { index, meta in
        let caseIndent = index == 0 ? "" : "                "
        if hasMainActor {
            return """
                \(caseIndent)case prefix + "\(meta.storageKey)":
                \(caseIndent)    MainActor.assumeIsolated {
                \(caseIndent)        let newValue = UserDefaultsWrapper.getValue(fullKey, host._default_value_of_\(meta.propertyID), host._userDefaults)
                \(caseIndent)        if host.shouldSetValue(newValue, host._\(meta.propertyID)) {
                \(caseIndent)            host._\(meta.propertyID) = newValue
                \(caseIndent)            host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
                \(caseIndent)        }
                \(caseIndent)    }
                """
        } else {
            return """
                \(caseIndent)case prefix + "\(meta.storageKey)":
                \(caseIndent)    let newValue = UserDefaultsWrapper.getValue(fullKey, host._default_value_of_\(meta.propertyID), host._userDefaults)
                \(caseIndent)    if host.shouldSetValue(newValue, host._\(meta.propertyID)) {
                \(caseIndent)        host._\(meta.propertyID) = newValue
                \(caseIndent)        host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
                \(caseIndent)    }
                """
        }
    }.joined(separator: "\n")
}

func makeCloudObservationCaseCode(
    metas: [PersistedPropertyMeta],
    hasMainActor: Bool
) -> String {
    metas.enumerated().map { index, meta in
        let caseIndent = index == 0 ? "" : "                "
        if hasMainActor {
            return """
                \(caseIndent)case prefix + "\(meta.storageKey)":
                \(caseIndent)    MainActor.assumeIsolated {
                \(caseIndent)        host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
                \(caseIndent)    }
                """
        } else {
            return """
                \(caseIndent)case prefix + "\(meta.storageKey)": host._$observationRegistrar.withMutation(of: host, keyPath: \\.\(meta.propertyID)) {}
                """
        }
    }.joined(separator: "\n")
}
