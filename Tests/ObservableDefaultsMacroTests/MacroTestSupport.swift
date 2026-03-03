import Foundation
import ObservableDefaultsMacros
import SwiftBasicFormat
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

struct MacroExpansionResult {
    let expandedSource: String
    let formattedExpandedSource: String
    let diagnostics: [String]
}

enum MacroTestSupportError: Error, CustomStringConvertible {
    case unexpectedDiagnostics(fixtureName: String, diagnostics: [String])
    case missingSnapshot(path: String)
    case snapshotMismatch(snapshotName: String)

    var description: String {
        switch self {
        case let .unexpectedDiagnostics(fixtureName, diagnostics):
            return "Unexpected diagnostics for fixture \(fixtureName):\n\(diagnostics.joined(separator: "\n"))"
        case let .missingSnapshot(path):
            return "Missing snapshot at \(path). Re-run tests with UPDATE_SNAPSHOTS=1 to create it."
        case let .snapshotMismatch(snapshotName):
            return "Snapshot mismatch at \(snapshotName). Re-run tests with UPDATE_SNAPSHOTS=1 to update."
        }
    }
}

enum MacroTestSupport {
    static let indentationWidth: Trivia = .spaces(4)

    static let macroSpecs: [String: MacroSpec] = [
        "ObservableDefaults": MacroSpec(type: ObservableDefaultsMacros.self, conformances: ["Observable"]),
        "ObservableCloud": MacroSpec(type: ObservableCloudMacros.self, conformances: ["Observable"]),
        "DefaultsBacked": MacroSpec(type: DefaultsBackedMacro.self),
        "DefaultsKey": MacroSpec(type: DefaultsKeyMacro.self),
        "CloudBacked": MacroSpec(type: CloudBackedMacro.self),
        "CloudKey": MacroSpec(type: CloudKeyMacro.self),
        "ObservableOnly": MacroSpec(type: ObservableOnlyMacro.self),
        "Ignore": MacroSpec(type: IgnoreMacro.self),
    ]

    static func expandFixture(named fixtureName: String) throws -> MacroExpansionResult {
        try expand(
            source: fixtureSource(named: fixtureName),
            fileName: "\(fixtureName).swift")
    }

    static func expand(source: String, fileName: String = "test.swift") throws -> MacroExpansionResult {
        let originalSourceFile = Parser.parse(source: source)
        let context = BasicMacroExpansionContext(
            sourceFiles: [originalSourceFile: .init(moduleName: "ObservableDefaultsMacroTests", fullFilePath: fileName)]
        )

        func contextGenerator(_ syntax: Syntax) -> BasicMacroExpansionContext {
            BasicMacroExpansionContext(
                sharingWith: context,
                lexicalContext: syntax.allMacroLexicalContexts())
        }

        let expandedSourceFile = originalSourceFile.expand(
            macroSpecs: macroSpecs,
            contextGenerator: contextGenerator,
            indentationWidth: indentationWidth)

        let format = BasicFormat(indentationWidth: indentationWidth)

        return MacroExpansionResult(
            expandedSource: trimmedSource(expandedSourceFile.description),
            formattedExpandedSource: trimmedSource(
                expandedSourceFile.formatted(using: format).description),
            diagnostics: context.diagnostics.map { String(describing: $0.message) })
    }

    static func assertExpansionSnapshot(
        fixtureName: String
    ) throws {
        let result = try expandFixture(named: fixtureName)
        if !result.diagnostics.isEmpty {
            throw MacroTestSupportError.unexpectedDiagnostics(
                fixtureName: fixtureName,
                diagnostics: result.diagnostics)
        }

        try assertSnapshot(
            actual: result.expandedSource,
            snapshotURL: snapshotURL(for: fixtureName, suffix: "expanded.swift"))
        try assertSnapshot(
            actual: result.formattedExpandedSource,
            snapshotURL: snapshotURL(for: fixtureName, suffix: "formatted.swift"))
    }

    static func fixtureSource(named fixtureName: String) throws -> String {
        try String(contentsOf: fixtureURL(for: fixtureName), encoding: .utf8)
    }

    static func fixtureURL(for fixtureName: String) -> URL {
        testDataDirectory.appendingPathComponent("Fixtures").appendingPathComponent("\(fixtureName).input")
    }

    static func snapshotURL(for fixtureName: String, suffix: String) -> URL {
        testDataDirectory.appendingPathComponent("__Snapshots__").appendingPathComponent("\(fixtureName).\(suffix)")
    }

    static func assertSnapshot(
        actual: String,
        snapshotURL: URL
    ) throws {
        let shouldUpdateSnapshots = ProcessInfo.processInfo.environment["UPDATE_SNAPSHOTS"] == "1"

        if shouldUpdateSnapshots {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            try actual.write(to: snapshotURL, atomically: true, encoding: .utf8)
            return
        }

        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            throw MacroTestSupportError.missingSnapshot(path: snapshotURL.path)
        }

        let expected = try String(contentsOf: snapshotURL, encoding: .utf8)
        guard actual == expected else {
            throw MacroTestSupportError.snapshotMismatch(snapshotName: snapshotURL.lastPathComponent)
        }
    }

    private static var testDataDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }

    private static func trimmedSource(_ source: String) -> String {
        source
            .replacingOccurrences(of: #"\A[\n\r]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[\n\r]+\z"#, with: "", options: .regularExpression)
    }
}
