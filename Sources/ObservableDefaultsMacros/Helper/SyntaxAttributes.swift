import SwiftSyntax

extension AttributeListSyntax {
    var containsMainActorAttribute: Bool {
        contains(where: { attribute in
            if case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                return identifierType.name.text == "MainActor"
            }
            return false
        })
    }

    func extractValue<T>(forAttribute attributeName: String, argument argumentName: String) -> T? {
        for attribute in self {
            if let value: T = attribute.extractValue(
                forAttribute: attributeName,
                argument: argumentName)
            {
                return value
            }
        }
        return nil
    }

    func expression(
        forAttribute attributeName: String,
        argument argumentName: String
    ) -> ExprSyntax? {
        for attribute in self {
            if let expression = attribute.expression(
                forAttribute: attributeName,
                argument: argumentName)
            {
                return expression
            }
        }
        return nil
    }
}

extension ExprSyntax {
    var booleanLiteralValue: Bool? {
        guard let booleanLiteral = self.as(BooleanLiteralExprSyntax.self) else {
            return nil
        }
        return booleanLiteral.literal.tokenKind == .keyword(.true)
    }

    var stringLiteralValue: String? {
        guard let stringLiteral = self.as(StringLiteralExprSyntax.self) else {
            return nil
        }
        return stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
    }

    var trimmedStringLiteralValue: String? {
        stringLiteralValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension LabeledExprListSyntax {
    func expression(forLabel labelName: String) -> ExprSyntax? {
        first(where: { $0.label?.text == labelName })?.expression
    }

    func booleanLiteralValue(forLabel labelName: String) -> Bool? {
        expression(forLabel: labelName)?.booleanLiteralValue
    }

    func trimmedStringLiteralValue(forLabel labelName: String) -> String? {
        expression(forLabel: labelName)?.trimmedStringLiteralValue
    }
}

extension AttributeListSyntax.Element {
    func extractValue<T>(forAttribute attributeName: String, argument argumentName: String) -> T? {
        guard case let .attribute(attributeNode) = self,
            let identifierType = attributeNode.attributeName.as(IdentifierTypeSyntax.self),
            identifierType.name.text == attributeName,
            let arguments = attributeNode.arguments?.as(LabeledExprListSyntax.self)
        else {
            return nil
        }

        for argument in arguments where argument.label?.text == argumentName {
            if let value = extractValueFromExpression(argument.expression) as? T {
                return value
            }
        }

        return nil
    }

    func expression(
        forAttribute attributeName: String,
        argument argumentName: String
    ) -> ExprSyntax? {
        guard case let .attribute(attributeNode) = self,
            let identifierType = attributeNode.attributeName.as(IdentifierTypeSyntax.self),
            identifierType.name.text == attributeName,
            let arguments = attributeNode.arguments?.as(LabeledExprListSyntax.self)
        else {
            return nil
        }

        for argument in arguments where argument.label?.text == argumentName {
            return argument.expression
        }

        return nil
    }

    private func extractValueFromExpression(_ expression: ExprSyntax) -> Any? {
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
        } else if let integerLiteral = expression.as(IntegerLiteralExprSyntax.self) {
            return Int(integerLiteral.literal.text)
        } else if let floatLiteral = expression.as(FloatLiteralExprSyntax.self) {
            return Double(floatLiteral.literal.text)
        } else if let booleanLiteral = expression.as(BooleanLiteralExprSyntax.self) {
            return booleanLiteral.literal.tokenKind == .keyword(.true)
        }
        return nil
    }
}
