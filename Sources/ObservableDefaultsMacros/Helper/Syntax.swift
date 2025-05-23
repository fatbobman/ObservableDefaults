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
    // Determine if it's a mutable variable and not a computed property
    var isMutableAndNotComputed: Bool {
        bindingSpecifier.tokenKind == .keyword(.var) && !isComputed
    }

    // Check if an attribute with a given name exists
    func hasAttribute(named attributeName: String) -> Bool {
        attributes.contains(where: { attribute in
            if case let .attribute(attr) = attribute,
               let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                return identifierType.name.text == attributeName
            }
            return false
        })
    }

    // Only observable, not persistent
    var isObservable: Bool {
        isMutableAndNotComputed && !hasAttribute(named: IgnoreMacro.name)
    }

    // Persistent
    var isPersistent: Bool {
        isMutableAndNotComputed && !hasAttribute(named: IgnoreMacro.name) &&
            !hasAttribute(named: ObservableOnlyMacro.name)
    }

    // Get the identifier of the variable
    var identifier: TokenSyntax? {
        // For example, the identifier for `var name:String = "hello"` is "name"
        identifierPattern?.identifier
    }

    // Check if a specific macro application exists in the variable declaration
    func hasMacroApplication(_ name: String) -> Bool {
        // Iterate through the attribute list, checking each attribute's token
        for attribute in attributes {
            switch attribute {
                case let .attribute(attr):
                    // If the attribute's token list contains the specified macro name, return true
                    if attr.attributeName.tokens(viewMode: .all)
                        .map(\.tokenKind) == [.identifier(name)]
                    {
                        return true
                    }
                default:
                    break
            }
        }
        // If no specific macro application is found, return false
        return false
    }

    // Get the identifier pattern of the variable declaration
    var identifierPattern: IdentifierPatternSyntax? {
        // Get the first binding's pattern from the binding list, if it's an identifier pattern,
        // return it
        // For example, if the variable declaration is `var name: String`, the returned identifier
        // pattern is `name`
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)
    }

    // Check if the variable is a computed property
    var isComputed: Bool {
        // If there's a get accessor, it's a computed property
        if !accessorsMatching({ $0 == .keyword(.get) }).isEmpty {
            true
        } else {
            // If there's a getter accessor in the binding list, it's a computed property
            bindings.contains { binding in
                if case .getter = binding.accessorBlock?.accessors {
                    true
                } else {
                    false
                }
            }
        }
    }

    // Filter accessors based on conditions
    // Example usage
    // Suppose we have a variable declaration with multiple accessors
    // var exampleProperty: Int {
    //   get { return 0 }
    //   set { }
    //   didSet { }
    // }
    // We want to get all didSet accessors
    // Using the accessorsMatching function, we can do this
    // let didSetAccessors = exampleProperty.accessorsMatching { $0 == .keyword(.didSet) }
    // didSetAccessors will contain all didSet accessors
    func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
        // Convert the binding list to an accessor list
        let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
            switch patternBinding.accessorBlock?.accessors {
                case let .accessors(accessors):
                    accessors
                default:
                    nil
            }
        }.flatMap(\.self)
        // Filter accessors based on conditions
        return accessors.compactMap { accessor in
            if predicate(accessor.accessorSpecifier.tokenKind) {
                accessor
            } else {
                nil
            }
        }
    }

    func privatePrefixed(
        _ prefix: String,
        addingAttribute attribute: AttributeSyntax) -> VariableDeclSyntax
    {
        let newAttributes = attributes + [.attribute(attribute)]
        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: newAttributes,
            modifiers: modifiers.privatePrefixed(prefix),
            bindingSpecifier: TokenSyntax(
                bindingSpecifier.tokenKind,
                leadingTrivia: .space,
                trailingTrivia: .space,
                presence: .present),
            bindings: bindings.privatePrefixed(prefix),
            trailingTrivia: trailingTrivia)
    }

    func privatePrefixed(_ prefix: String) -> VariableDeclSyntax {
        VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: [],
            modifiers: modifiers.privatePrefixed(prefix),
            bindingSpecifier: TokenSyntax(
                bindingSpecifier.tokenKind,
                leadingTrivia: .space,
                trailingTrivia: .space,
                presence: .present),
            bindings: bindings.privatePrefixed(prefix),
            trailingTrivia: trailingTrivia)
    }
}

extension AttributeListSyntax {
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
}

extension AttributeListSyntax.Element {
    /**
     Extracts a value of a specific type from an attribute.

     - Parameters:
       - attributeName: The name of the attribute from which to extract the value.
       - argumentName: The name of the argument from which to extract the value.

     - Returns: The extracted value, or nil if the type does not match or the corresponding argument is not found.
     */
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

    /**
     Extracts a value from an expression.

     - Parameters:
       - expression: The expression from which to extract the value.

     - Returns: The extracted value, or nil if the expression type is not supported.
     */
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
        // More types can be added as needed
        return nil
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
        let modifier = DeclModifierSyntax(name: "private", trailingTrivia: .space)
        return [modifier] + filter {
            switch $0.name.tokenKind {
                case let .keyword(keyword):
                    switch keyword {
                        case .fileprivate: fallthrough
                        case .private: fallthrough
                        case .internal: fallthrough
                        case .package: fallthrough
                        case .public:
                            return false
                        default:
                            return true
                    }
                default:
                    return true
            }
        }
    }

    init(keyword: Keyword) {
        self.init([DeclModifierSyntax(name: .keyword(keyword))])
    }
}

extension TokenSyntax {
    func privatePrefixed(_ prefix: String) -> TokenSyntax {
        switch tokenKind {
            case let .identifier(identifier):
                TokenSyntax(
                    .identifier(prefix + identifier),
                    leadingTrivia: leadingTrivia,
                    trailingTrivia: trailingTrivia,
                    presence: presence)
            default:
                self
        }
    }
}

extension PatternBindingListSyntax {
    func privatePrefixed(_ prefix: String) -> PatternBindingListSyntax {
        var bindings = map(\.self)
        for index in 0 ..< bindings.count {
            let binding = bindings[index]
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                bindings[index] = PatternBindingSyntax(
                    leadingTrivia: binding.leadingTrivia,
                    pattern: IdentifierPatternSyntax(
                        leadingTrivia: identifier.leadingTrivia,
                        identifier: identifier.identifier.privatePrefixed(prefix),
                        trailingTrivia: identifier.trailingTrivia),
                    typeAnnotation: binding.typeAnnotation,
                    initializer: binding.initializer,
                    accessorBlock: binding.accessorBlock,
                    trailingComma: binding.trailingComma,
                    trailingTrivia: binding.trailingTrivia)
            }
        }

        return PatternBindingListSyntax(bindings)
    }
}
