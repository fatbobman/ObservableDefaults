import SwiftSyntax

extension VariableDeclSyntax {
    var isMutableAndNotComputed: Bool {
        bindingSpecifier.tokenKind == .keyword(.var) && !isComputed
    }

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

    var isStatic: Bool {
        modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static)
        }
    }

    var hasWillOrDidSetObserver: Bool {
        !accessorsMatching {
            $0 == .keyword(.willSet) || $0 == .keyword(.didSet)
        }.isEmpty
    }

    var isObservable: Bool {
        isMutableAndNotComputed && !hasAttribute(named: IgnoreMacro.name) && !isStatic
    }

    var isPersistent: Bool {
        isMutableAndNotComputed && !hasAttribute(named: IgnoreMacro.name) && !hasAttribute(named: ObservableOnlyMacro.name) && !isStatic
    }

    var identifier: TokenSyntax? {
        identifierPattern?.identifier
    }

    var identifierText: String {
        identifier?.text ?? ""
    }

    func hasMacroApplication(_ name: String) -> Bool {
        for attribute in attributes {
            switch attribute {
            case let .attribute(attr):
                if attr.attributeName.tokens(viewMode: .all)
                    .map(\.tokenKind) == [.identifier(name)]
                {
                    return true
                }
            default:
                break
            }
        }
        return false
    }

    var identifierPattern: IdentifierPatternSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)
    }

    var isComputed: Bool {
        if !accessorsMatching({ $0 == .keyword(.get) }).isEmpty {
            true
        } else {
            bindings.contains { binding in
                if case .getter = binding.accessorBlock?.accessors {
                    true
                } else {
                    false
                }
            }
        }
    }

    func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
        let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
            switch patternBinding.accessorBlock?.accessors {
            case let .accessors(accessors):
                accessors
            default:
                nil
            }
        }.flatMap(\.self)
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
        addingAttribute attribute: AttributeSyntax
    ) -> VariableDeclSyntax {
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
            bindings: bindings.privatePrefixed(prefix, preservingAccessors: true),
            trailingTrivia: trailingTrivia)
    }

    func privatePrefixedWithoutAccessors(_ prefix: String) -> VariableDeclSyntax {
        VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: [],
            modifiers: modifiers.privatePrefixed(prefix),
            bindingSpecifier: TokenSyntax(
                bindingSpecifier.tokenKind,
                leadingTrivia: .space,
                trailingTrivia: .space,
                presence: .present),
            bindings: bindings.privatePrefixed(prefix, preservingAccessors: false),
            trailingTrivia: trailingTrivia)
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
        let modifier = DeclModifierSyntax(name: "private", trailingTrivia: .space)
        return [modifier]
            + filter {
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
    func privatePrefixed(
        _ prefix: String,
        preservingAccessors: Bool = true
    ) -> PatternBindingListSyntax {
        var bindings = map(\.self)
        for index in 0..<bindings.count {
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
                    accessorBlock: preservingAccessors ? binding.accessorBlock : nil,
                    trailingComma: binding.trailingComma,
                    trailingTrivia: binding.trailingTrivia)
            }
        }

        return PatternBindingListSyntax(bindings)
    }
}
