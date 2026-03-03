import SwiftParser
import SwiftSyntax
import Testing

@Suite("Macro Structure")
struct MacroStructureTests {
    @Test("ObservableDefaults basic structure")
    func observableDefaultsBasicStructure() throws {
        let result = try MacroTestSupport.expandFixture(named: "ObservableDefaultsBasic")

        #expect(result.diagnostics.isEmpty)
        #expect(result.expandedSource.contains("internal let _$observationRegistrar = Observation.ObservationRegistrar()"))
        #expect(result.expandedSource.contains("private var _userDefaults: Foundation.UserDefaults = Foundation.UserDefaults.standard"))
        #expect(result.expandedSource.contains("private let _defaultsKeyPathMap"))
        #expect(result.expandedSource.contains("private func observerStarter"))

        let tree = Parser.parse(source: result.expandedSource)
        let classes = tree.statements.compactMap { $0.item.as(ClassDeclSyntax.self) }
        #expect(classes.count == 1)
        #expect(classes.first?.name.text == "DefaultsBasicFixture")
    }

    @Test("ObserveFirst defaults only maps explicitly backed properties")
    func observeFirstDefaultsOnlyMapsBackedProperties() throws {
        let result = try MacroTestSupport.expandFixture(named: "ObservableDefaultsObserveFirst")

        #expect(result.diagnostics.isEmpty)
        #expect(result.expandedSource.contains(#"\DefaultsObserveFirstFixture.persisted: "stored_name""#))
        #expect(!result.expandedSource.contains(#"\DefaultsObserveFirstFixture.transient:"#))
        #expect(!result.expandedSource.contains(#"\DefaultsObserveFirstFixture.derived:"#))
    }

    @Test("ObserveFirst cloud keeps development mode and backed storage")
    func observeFirstCloudStructure() throws {
        let result = try MacroTestSupport.expandFixture(named: "ObservableCloudObserveFirst")

        #expect(result.diagnostics.isEmpty)
        #expect(result.expandedSource.contains("public var _developmentMode_: Bool"))
        #expect(result.expandedSource.contains("private var _cloudObserver: CloudObservation?"))
        #expect(result.expandedSource.contains("var _theme: String = \"light\""))
        #expect(result.expandedSource.contains("let _default_value_of_theme"))
        #expect(result.expandedSource.contains("var _ephemeral: String = \"scratch\""))
        #expect(result.expandedSource.contains(#"case prefix + "theme":"#))
        #expect(!result.expandedSource.contains(#"case prefix + "ephemeral":"#))
    }

    @Test("defaultIsolationIsMainActor adds MainActor-specific generated code for defaults")
    func defaultsDefaultIsolationMainActorStructure() throws {
        let result = try MacroTestSupport.expandFixture(named: "ObservableDefaultsDefaultIsolationMainActor")

        #expect(result.diagnostics.isEmpty)
        #expect(result.expandedSource.contains("MainActor.assumeIsolated"))
        #expect(result.expandedSource.contains("@MainActor"))
        #expect(result.expandedSource.contains("deinit {"))
    }

    @Test("defaultIsolationIsMainActor adds MainActor-specific generated code for cloud")
    func cloudDefaultIsolationMainActorStructure() throws {
        let result = try MacroTestSupport.expandFixture(named: "ObservableCloudDefaultIsolationMainActor")

        #expect(result.diagnostics.isEmpty)
        #expect(result.expandedSource.contains("MainActor.assumeIsolated"))
        #expect(result.expandedSource.contains("@MainActor"))
        #expect(result.expandedSource.contains("deinit {"))
    }
}
