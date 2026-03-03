import Testing

@Suite("Macro Diagnostics")
struct MacroDiagnosticTests {
    @Test("ObservableDefaults rejects non-literal suiteName")
    func defaultsRejectsNonLiteralSuiteName() throws {
        let result = try MacroTestSupport.expand(
            source: """
                let suite = "group.test"

                @ObservableDefaults(suiteName: suite)
                final class Fixture {
                    var name: String = "fat"
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@ObservableDefaults parameter 'suiteName' must be a string literal"))
    }

    @Test("DefaultsBacked rejects non-literal custom key")
    func defaultsBackedRejectsNonLiteralKey() throws {
        let result = try MacroTestSupport.expand(
            source: """
                @ObservableDefaults
                final class Fixture {
                    @DefaultsBacked(userDefaultsKey: 1)
                    var name: String = "fat"
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@DefaultsBacked parameter 'userDefaultsKey' must be a string literal"))
    }

    @Test("DefaultsBacked requires initializer for non-optional")
    func defaultsBackedRequiresInitializer() throws {
        let result = try MacroTestSupport.expand(
            source: """
                @ObservableDefaults
                final class Fixture {
                    @DefaultsBacked
                    var name: String
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@ObservableDefaults properties must have an initial value"))
    }

    @Test("DefaultsBacked warns that willSet and didSet are ignored")
    func defaultsBackedWarnsOnObservers() throws {
        let result = try MacroTestSupport.expand(
            source: """
                @ObservableDefaults
                final class Fixture {
                    @DefaultsBacked
                    var name: String = "fat" {
                        willSet {}
                        didSet {}
                    }
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@DefaultsBacked does not support willSet/didSet"))
    }
}
