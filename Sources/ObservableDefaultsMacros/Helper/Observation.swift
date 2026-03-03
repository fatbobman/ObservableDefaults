import SwiftSyntax
import SwiftSyntaxBuilder

func makeObservationRegistrarSyntax() -> DeclSyntax {
    """
    internal let _$observationRegistrar = Observation.ObservationRegistrar()
    """
}

func makeAccessFunctionSyntax(className: IdentifierPatternSyntax) -> DeclSyntax {
    """
    internal nonisolated func access<Member>(keyPath: KeyPath<\(className), Member>) {
      _$observationRegistrar.access(self, keyPath: keyPath)
    }
    """
}

func makeWithMutationFunctionSyntax(className: IdentifierPatternSyntax) -> DeclSyntax {
    """
    /// Performs a mutation on the specified keyPath and notifies observers.
    /// - Parameters:
    ///   - keyPath: The key path to the property being mutated
    ///   - mutation: The mutation closure to execute
    /// - Returns: The result of the mutation closure
    internal nonisolated func withMutation<Member, T>(keyPath: KeyPath<\(
        className), Member>, _ mutation: () throws -> T) rethrows -> T {
      try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }
    """
}

let shouldSetValueSyntax: DeclSyntax =
    """
    private nonisolated func shouldSetValue<T>(_ lhs: T, _ rhs: T) -> Bool {
       true
    }

    private nonisolated func shouldSetValue<T: Equatable>(_ lhs: T, _ rhs: T) -> Bool {
       lhs != rhs
    }

    private nonisolated func shouldSetValue<T: AnyObject>(_ lhs: T, _ rhs: T) -> Bool {
       lhs !== rhs
    }

    private nonisolated func shouldSetValue<T: Equatable & AnyObject>(_ lhs: T, _ rhs: T) -> Bool {
        lhs != rhs
    }
    """
