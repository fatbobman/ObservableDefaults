//
//  ------------------------------------------------
//  Original project: ObservableDefaults
//  Created on 2024/10/8 by Fatbobman(东坡肘子)
//  X: @fatbobman
//  Mastodon: @fatbobman@mastodon.social
//  GitHub: @fatbobman
//  Blog: https://fatbobman.com
//  ------------------------------------------------
//  Copyright © 2024-present Fatbobman. All rights reserved.

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension VariableDeclSyntax {
    // 判断是否为 var，且不是计算属性
    var isMutableAndNotComputed: Bool {
        return bindingSpecifier.tokenKind == .keyword(.var) && !isComputed
    }

    // 根据给定的标识（字符串），返回是否存在
    func hasAttribute(named attributeName: String) -> Bool {
        return attributes.contains(where: { attribute in
            if case let .attribute(attr) = attribute,
               let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                return identifierType.name.text == attributeName
            }
            return false
        })
    }

    // 仅观察，不可持久化
    var isObservable: Bool {
        isMutableAndNotComputed && !hasAttribute(named: IgnoreMacro.name)
    }

    // 可持久化
    var isPersistent: Bool {
        isMutableAndNotComputed && !hasAttribute(named: IgnoreMacro.name) && !hasAttribute(named: ObservableOnlyMacro.name)
    }
}

extension AttributeListSyntax {
    func extractValue<T>(forAttribute attributeName: String, argument argumentName: String) -> T? {
        for attribute in self {
            if let value: T = attribute.extractValue(forAttribute: attributeName, argument: argumentName) {
                return value
            }
        }
        return nil
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
        // 可以根据需要添加更多类型
        return nil
    }
}
