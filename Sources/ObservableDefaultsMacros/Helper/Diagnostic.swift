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

struct ObservableDefaultsWarningMessage: DiagnosticMessage {
    let message: String
    let diagnosticID = MessageID(domain: "ObservableDefaultsMacros", id: "warning")
    let severity: DiagnosticSeverity = .warning
}

func createDiagnostic(
    node: some SyntaxProtocol,
    message: String,
    fixItMessage: String? = nil,
    fixIt: FixIt.Change? = nil) -> Diagnostic
{
    var fixIts: [FixIt] = []
    if let fixItMessage, let fixIt {
        fixIts = [
            FixIt(message: MacroExpansionFixItMessage(fixItMessage), changes: [fixIt]),
        ]
    }

    return Diagnostic(
        node: node,
        message: MacroExpansionErrorMessage(message),
        fixIts: fixIts)
}

func createWarningDiagnostic(
    node: some SyntaxProtocol,
    message: String) -> Diagnostic
{
    Diagnostic(
        node: node,
        message: ObservableDefaultsWarningMessage(message: message))
}

extension Diagnostic {
    static func variableRequired(property: VariableDeclSyntax, macroType: MacroType) -> Diagnostic {
        let diagnostic = createDiagnostic(
            node: property.bindingSpecifier,
            message: "\(macroType.rawValue) can only be used on var properties",
            fixItMessage: "Change 'let' to 'var'",
            fixIt: FixIt.Change.replace(
                oldNode: Syntax(property.bindingSpecifier),
                newNode: Syntax(TokenSyntax(.keyword(.var), presence: .present))))
        return diagnostic
    }

    static func initializerRequired(
        property: VariableDeclSyntax,
        macroType: MacroType) -> Diagnostic
    {
        createDiagnostic(
            node: property,
            message: "\(macroType.rawValue) properties must have an initial value",
            fixItMessage: "Add an initial value",
            fixIt: FixIt.Change.replace(
                oldNode: Syntax(property),
                newNode: Syntax(
                    VariableDeclSyntax(
                        attributes: property.attributes,
                        modifiers: property.modifiers,
                        bindingSpecifier: property.bindingSpecifier,
                        bindings: PatternBindingListSyntax([
                            PatternBindingSyntax(
                                pattern: property.bindings.first!.pattern,
                                typeAnnotation: property.bindings.first!.typeAnnotation,
                                initializer: InitializerClauseSyntax(
                                    equal: .equalToken(
                                        leadingTrivia: .spaces(1),
                                        trailingTrivia: .spaces(1)),
                                    value: ExprSyntax("<#initializer#>"))),
                        ])))))
    }

    static func explicitTypeAnnotationRequired(
        property: VariableDeclSyntax,
        macroType: MacroType) -> Diagnostic
    {
        createDiagnostic(
            node: property,
            message: "\(macroType.rawValue) properties must have an explicit type annotation. var name: String",
            fixItMessage: "Add a type annotation",
            fixIt: FixIt.Change.replace(
                oldNode: Syntax(property),
                newNode: Syntax(
                    VariableDeclSyntax(
                        attributes: property.attributes,
                        modifiers: property.modifiers,
                        bindingSpecifier: property.bindingSpecifier,
                        bindings: PatternBindingListSyntax([
                            PatternBindingSyntax(
                                pattern: property.bindings.first!.pattern,
                                typeAnnotation: TypeAnnotationSyntax(
                                    colon: .colonToken(trailingTrivia: .spaces(1)),
                                    type: TypeSyntax("<#Type#> ")),
                                initializer: property.bindings.first!.initializer),
                        ])))))
    }

    static func stringLiteralRequired(
        expression: ExprSyntax,
        argumentName: String,
        attributeName: String) -> Diagnostic
    {
        createDiagnostic(
            node: expression,
            message: "\(attributeName) parameter '\(argumentName)' must be a string literal")
    }

    static func observersNotSupported(
        property: VariableDeclSyntax,
        attributeName: String) -> Diagnostic
    {
        createWarningDiagnostic(
            node: property,
            message: "\(attributeName) does not support willSet/didSet. These observers will be ignored.")
    }

}
