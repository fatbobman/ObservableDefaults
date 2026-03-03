import SwiftSyntax

func makeObservationClassPreamble(
    observerPropertyName: String,
    observerTypeName: String,
    description: String
) -> String {
    """
    private var \(observerPropertyName): \(observerTypeName)?

    /// Manages \(description).
    ///
    /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
    private final class \(observerTypeName): @unchecked Sendable {
    """
}

func makeObserverDeinitSyntax(
    defaultIsolationIsMainActor: Bool = false,
    body: String
) -> String {
    let mainActorAttribute = defaultIsolationIsMainActor ? "    @MainActor\n" : ""
    return """
        \(mainActorAttribute)    deinit {
        \(body)
            }
        """
}
