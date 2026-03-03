import Testing

@Suite("Macro Expansion Snapshot")
struct MacroExpansionSnapshotTests {
    @Test("ObservableDefaults basic snapshot")
    func observableDefaultsBasicSnapshot() throws {
        try MacroTestSupport.assertExpansionSnapshot(fixtureName: "ObservableDefaultsBasic")
    }

    @Test("ObservableDefaults observeFirst snapshot")
    func observableDefaultsObserveFirstSnapshot() throws {
        try MacroTestSupport.assertExpansionSnapshot(fixtureName: "ObservableDefaultsObserveFirst")
    }

    @Test("ObservableCloud observeFirst snapshot")
    func observableCloudObserveFirstSnapshot() throws {
        try MacroTestSupport.assertExpansionSnapshot(fixtureName: "ObservableCloudObserveFirst")
    }

    @Test("ObservableDefaults defaultIsolationIsMainActor snapshot")
    func observableDefaultsDefaultIsolationMainActorSnapshot() throws {
        try MacroTestSupport.assertExpansionSnapshot(fixtureName: "ObservableDefaultsDefaultIsolationMainActor")
    }

    @Test("ObservableCloud defaultIsolationIsMainActor snapshot")
    func observableCloudDefaultIsolationMainActorSnapshot() throws {
        try MacroTestSupport.assertExpansionSnapshot(fixtureName: "ObservableCloudDefaultIsolationMainActor")
    }
}
