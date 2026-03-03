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

    @Test("ObservableDefaults rejects non-literal prefix")
    func defaultsRejectsNonLiteralPrefix() throws {
        let result = try MacroTestSupport.expand(
            source: """
                let prefix = "app_"

                @ObservableDefaults(prefix: prefix)
                final class Fixture {
                    var name: String = "fat"
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@ObservableDefaults parameter 'prefix' must be a string literal"))
    }

    @Test("ObservableCloud rejects non-literal prefix")
    func cloudRejectsNonLiteralPrefix() throws {
        let result = try MacroTestSupport.expand(
            source: """
                let prefix = "app_"

                @ObservableCloud(prefix: prefix)
                final class Fixture {
                    var name: String = "fat"
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@ObservableCloud parameter 'prefix' must be a string literal"))
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

    @Test("CloudBacked rejects non-literal custom key")
    func cloudBackedRejectsNonLiteralKey() throws {
        let result = try MacroTestSupport.expand(
            source: """
                @ObservableCloud
                final class Fixture {
                    @CloudBacked(keyValueStoreKey: 1)
                    var name: String = "fat"
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@CloudBacked parameter 'keyValueStoreKey' must be a string literal"))
    }

    @Test("CloudBacked requires initializer for non-optional")
    func cloudBackedRequiresInitializer() throws {
        let result = try MacroTestSupport.expand(
            source: """
                @ObservableCloud
                final class Fixture {
                    @CloudBacked
                    var name: String
                }
                """)

        #expect(result.diagnostics.count == 1)
        #expect(result.diagnostics[0].contains("@ObservableCloud properties must have an initial value"))
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
