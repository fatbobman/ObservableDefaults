import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct BackedStorageKeyLookupResult {
    let keyString: String
    let invalidExpression: ExprSyntax?
    let invalidAttributeName: String?
}

func validateBackedProperty(
    property: VariableDeclSyntax,
    binding: PatternBindingSyntax,
    macroType: MacroType,
    attributeName: String,
    in context: some MacroExpansionContext
) -> Bool? {
    guard property.isPersistent else {
        let diagnostic = Diagnostic.variableRequired(property: property, macroType: macroType)
        context.diagnose(diagnostic)
        return nil
    }

    if property.hasWillOrDidSetObserver {
        context.diagnose(
            .observersNotSupported(
                property: property,
                attributeName: attributeName))
    }

    let isOptionalType = isOptionalStoredType(binding)
    if binding.initializer == nil && !isOptionalType {
        let diagnostic = Diagnostic.initializerRequired(property: property, macroType: macroType)
        context.diagnose(diagnostic)
        return nil
    }

    return isOptionalType
}

func lookupBackedStorageKey(
    property: VariableDeclSyntax,
    defaultKey: String,
    primaryAttribute: String,
    primaryArgument: String,
    fallbackAttribute: String,
    fallbackArgument: String
) -> BackedStorageKeyLookupResult {
    var invalidExpression: ExprSyntax?
    var invalidAttributeName: String?

    if let expression = property.attributes.expression(
        forAttribute: primaryAttribute,
        argument: primaryArgument)
    {
        invalidExpression = expression
        invalidAttributeName = "@\(primaryAttribute)"
    } else if let expression = property.attributes.expression(
        forAttribute: fallbackAttribute,
        argument: fallbackArgument)
    {
        invalidExpression = expression
        invalidAttributeName = "@\(fallbackAttribute)"
    }

    if let extractedKey: String = property.attributes.extractValue(
        forAttribute: primaryAttribute,
        argument: primaryArgument)
        ?? property.attributes.extractValue(
            forAttribute: fallbackAttribute,
            argument: fallbackArgument)
    {
        return BackedStorageKeyLookupResult(
            keyString: extractedKey,
            invalidExpression: nil,
            invalidAttributeName: nil)
    }

    return BackedStorageKeyLookupResult(
        keyString: defaultKey,
        invalidExpression: invalidExpression,
        invalidAttributeName: invalidAttributeName)
}
