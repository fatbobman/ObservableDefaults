import SwiftSyntax
import SwiftSyntaxBuilder

let defaultValuePrefixed = "_default_value_of_"

func isOptionalStoredType(_ binding: PatternBindingSyntax) -> Bool {
    guard let typeAnnotation = binding.typeAnnotation else {
        return false
    }

    let typeSyntax = typeAnnotation.type
    let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
    return typeSyntax.is(OptionalTypeSyntax.self)
        || typeSyntax.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        || typeName.contains("Optional")
}

func makeBackedStorageDecls(
    property: VariableDeclSyntax,
    binding: PatternBindingSyntax,
    identifier: IdentifierPatternSyntax
) -> [DeclSyntax] {
    let isOptionalType = isOptionalStoredType(binding)
    let storage = DeclSyntax(property.privatePrefixedWithoutAccessors("_"))
    let defaultStorage = makeDefaultValueStorageDecl(
        binding: binding,
        identifier: identifier,
        isOptionalType: isOptionalType)
    return [storage, defaultStorage]
}

private func makeDefaultValueStorageDecl(
    binding: PatternBindingSyntax,
    identifier: IdentifierPatternSyntax,
    isOptionalType: Bool
) -> DeclSyntax {
    if let initializer = binding.initializer {
        let initializerDescription = initializer.description
        if isOptionalType && initializerDescription.trimmingCharacters(in: .whitespacesAndNewlines) == "= nil" {
            return
                """
                // initial value storage, never change after initialization
                private let \(raw: defaultValuePrefixed)\(raw: identifier): \(raw: binding.typeAnnotation?.type.description ?? "Optional<Any>") = nil
                """
        }

        if let typeAnnotation = binding.typeAnnotation {
            return
                """
                // initial value storage, never change after initialization
                private let \(raw: defaultValuePrefixed)\(raw: identifier): \(raw: typeAnnotation.type.description) \(raw: initializerDescription)
                """
        }

        return
            """
            // initial value storage, never change after initialization
            private let \(raw: defaultValuePrefixed)\(raw: identifier) \(raw: initializerDescription)
            """
    }

    if isOptionalType {
        return
            """
            // initial value storage, never change after initialization
            private let \(raw: defaultValuePrefixed)\(raw: identifier): \(raw: binding.typeAnnotation?.type.description ?? "Optional<Any>") = nil
            """
    }

    return
        """
        // initial value storage, never change after initialization
        private let \(raw: defaultValuePrefixed)\(raw: identifier): Any? = nil
        """
}
