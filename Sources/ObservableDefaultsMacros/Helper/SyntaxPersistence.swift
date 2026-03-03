import SwiftSyntax

struct PersistedPropertyMeta {
    let storageKey: String
    let propertyID: String
}

extension VariableDeclSyntax {
    func storageKey(
        primaryAttribute: String,
        primaryArgument: String,
        fallbackAttribute: String,
        fallbackArgument: String
    ) -> String {
        attributes.extractValue(
            forAttribute: primaryAttribute,
            argument: primaryArgument)
            ?? attributes.extractValue(
                forAttribute: fallbackAttribute,
                argument: fallbackArgument)
            ?? identifierText
    }
}

extension ClassDeclSyntax {
    var hasExplicitMainActorAttribute: Bool {
        attributes.containsMainActorAttribute
    }

    var persistentProperties: [VariableDeclSyntax] {
        memberBlock.members.compactMap { member -> VariableDeclSyntax? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                varDecl.isPersistent
            else {
                return nil
            }
            return varDecl
        }
    }

    func persistentPropertyMetas(
        primaryAttribute: String,
        primaryArgument: String,
        fallbackAttribute: String,
        fallbackArgument: String,
        observeFirst: Bool = false,
        requiredBackedAttribute: String? = nil
    ) -> [PersistedPropertyMeta] {
        persistentProperties.compactMap { property in
            if observeFirst,
                let requiredBackedAttribute,
                !property.hasAttribute(named: requiredBackedAttribute)
            {
                return nil
            }

            return PersistedPropertyMeta(
                storageKey: property.storageKey(
                    primaryAttribute: primaryAttribute,
                    primaryArgument: primaryArgument,
                    fallbackAttribute: fallbackAttribute,
                    fallbackArgument: fallbackArgument),
                propertyID: property.identifierText)
        }
    }
}

func lexicalContextHasExplicitMainActor(_ lexicalContext: [Syntax]) -> Bool {
    for context in lexicalContext {
        if let classContext = context.as(ClassDeclSyntax.self) {
            return classContext.hasExplicitMainActorAttribute
        }
    }
    return false
}
