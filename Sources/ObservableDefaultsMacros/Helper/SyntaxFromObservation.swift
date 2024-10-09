// This portion of code is derived from ObservationMacros
// Source: https://github.com/swiftlang/swift/blob/main/lib/Macros/Sources/ObservationMacros/
// The original code is licensed under the Apache License.

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// 扩展DeclGroupSyntax
extension DeclGroupSyntax {
  // 获取成员函数的占位符
  // 这个函数用于获取成员函数的占位符，占位符是函数的签名
  // 例如，如果有一个成员函数 `func exampleFunction() -> Void`, 它的占位符将是 `exampleFunction() -> Void`
  var memberFunctionStandins: [FunctionDeclSyntax.SignatureStandin] {
    var standins = [FunctionDeclSyntax.SignatureStandin]()
    for member in memberBlock.members {
      if let function = member.decl.as(FunctionDeclSyntax.self) {
        standins.append(function.signatureStandin)
      }
    }
    return standins
  }

  // 检查是否有等效的成员函数
  // 这个函数用于检查是否有与其他函数等效的成员函数
  // 例如，如果有一个成员函数 `func exampleFunction() -> Void`, 它的占位符将是 `exampleFunction() -> Void`
  // 如果有一个函数 `func otherFunction() -> Void`, 它的占位符也是 `otherFunction() -> Void`
  // 那么这两个函数是等效的
  func hasMemberFunction(equvalentTo other: FunctionDeclSyntax) -> Bool {
    for member in memberBlock.members {
      if let function = member.decl.as(FunctionDeclSyntax.self) {
        if function.isEquivalent(to: other) {
          return true
        }
      }
    }
    return false
  }

  // 检查是否有等效的成员属性
  // 这个函数用于检查是否有与其他变量等效的成员属性
  // 例如，如果有一个成员属性 `var exampleProperty: Int`, 它的占位符将是 `exampleProperty: Int`
  // 如果有一个变量 `var otherProperty: Int`, 它的占位符也是 `otherProperty: Int`
  // 那么这两个变量是等效的
  func hasMemberProperty(equivalentTo other: VariableDeclSyntax) -> Bool {
    // 遍历成员块中的所有成员
    for member in memberBlock.members {
      // 如果成员是一个变量声明
      if let variable = member.decl.as(VariableDeclSyntax.self) {
        // 检查当前变量是否与传入的变量等效
        if variable.isEquivalent(to: other) {
          // 如果等效，则返回true
          return true
        }
      }
    }
    // 如果没有找到等效的变量，则返回false
    return false
  }

  // 获取定义的变量
  // 这个计算属性遍历成员块中的所有成员，检查每个成员是否是一个变量声明（VariableDeclSyntax）。
  // 如果是，则返回该变量声明，否则返回nil。最终返回一个包含所有变量声明的数组。
  // 例如，如果成员块中有一个成员 `var exampleVariable: Int`, 它将被包含在返回的数组中。
  var definedVariables: [VariableDeclSyntax] {
    memberBlock.members.compactMap { member in
      if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
        return variableDecl
      }
      return nil
    }
  }

  // 如果需要，将声明添加到声明列表
  // 这个函数检查传入的声明是否已经在成员块中存在，如果不存在，则将其添加到传入的声明列表中。
  // 它支持两种类型的声明：函数声明（FunctionDeclSyntax）和变量声明（VariableDeclSyntax）。
  // 对于函数声明，它会检查成员块中是否已经有一个等效的函数，如果没有，则将其添加到声明列表中。
  // 对于变量声明，它会检查成员块中是否已经有一个等效的变量，如果没有，则将其添加到声明列表中。
  // 例如，如果成员块中没有一个名为 `exampleFunction` 的函数，则可以使用这个函数将其添加到声明列表中：
  // ```
  // let exampleFunctionDecl = FunctionDeclSyntax(identifier: .init(stringLiteral: "exampleFunction"), parameters: [], returnType: .void)
  // addIfNeeded(exampleFunctionDecl, to: &declarations)
  // ```
  // 类似地，如果成员块中没有一个名为 `exampleProperty` 的变量，则可以使用这个函数将其添加到声明列表中：
  // ```
  // let examplePropertyDecl = VariableDeclSyntax(identifier: .init(stringLiteral: "exampleProperty"), typeAnnotation: .int)
  // addIfNeeded(examplePropertyDecl, to: &declarations)
  // ```
  func addIfNeeded(_ decl: DeclSyntax?, to declarations: inout [DeclSyntax]) {
    guard let decl else { return }
    if let fn = decl.as(FunctionDeclSyntax.self) {
      if !hasMemberFunction(equvalentTo: fn) {
        declarations.append(decl)
      }
    } else if let property = decl.as(VariableDeclSyntax.self) {
      if !hasMemberProperty(equivalentTo: property) {
        declarations.append(decl)
      }
    }
  }

  // 检查是否是类
  var isClass: Bool {
    return self.is(ClassDeclSyntax.self)
  }

  // 检查是否是Actor
  var isActor: Bool {
    return self.is(ActorDeclSyntax.self)
  }

  // 检查是否是枚举
  var isEnum: Bool {
    return self.is(EnumDeclSyntax.self)
  }

  // 检查是否是结构体
  var isStruct: Bool {
    return self.is(StructDeclSyntax.self)
  }
}

extension VariableDeclSyntax {
  // 获取变量声明的标识符模式
  var identifierPattern: IdentifierPatternSyntax? {
    // 从绑定列表中获取第一个绑定的模式，如果是标识符模式，则返回
    // 例如，如果变量声明是 `var name: String`, 则返回的标识符模式是 `name`
    bindings.first?.pattern.as(IdentifierPatternSyntax.self)
  }

  // 检查变量是否是实例变量
  var isInstance: Bool {
    // 遍历修饰符列表，检查每个修饰符的所有token
    for modifier in modifiers {
      for token in modifier.tokens(viewMode: .all) {
        // 如果token是静态或类修饰符，则返回false，表示不是实例变量
        if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
          return false
        }
      }
    }
    // 如果没有找到静态或类修饰符，则返回true，表示是实例变量
    return true
  }

  // 获取变量的标识符
  var identifier: TokenSyntax? {
    // 例如，var name:String = "hello" 对应的标识符是 "name"
    identifierPattern?.identifier
  }

  // 获取变量的类型
  var type: TypeSyntax? {
    // 从第一个绑定的类型注解中获取类型
    // 如果变量声明没有显式标注类型，则返回nil
    // 例如，如果变量声明是 `var name: String`, 则返回的类型是 `String`
    // 如果变量声明是 `var name`, 则返回nil
    bindings.first?.typeAnnotation?.type
  }

  // 根据条件过滤访问器
  // 示例用法
  // 假设我们有一个变量声明，包含多个访问器
  // var exampleProperty: Int {
  //   get { return 0 }
  //   set { }
  //   didSet { }
  // }
  // 我们想获取所有的didSet访问器
  // 使用accessorsMatching函数，我们可以这样做
  // let didSetAccessors = exampleProperty.accessorsMatching { $0 == .keyword(.didSet) }
  // didSetAccessors将包含所有的didSet访问器
  func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
    // 将绑定列表转换为访问器列表
    let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
      switch patternBinding.accessorBlock?.accessors {
      case let .accessors(accessors):
        return accessors
      default:
        return nil
      }
    }.flatMap { $0 }
    // 根据条件过滤访问器
    return accessors.compactMap { accessor in
      if predicate(accessor.accessorSpecifier.tokenKind) {
        return accessor
      } else {
        return nil
      }
    }
  }

  // 获取所有的willSet访问器
  var willSetAccessors: [AccessorDeclSyntax] {
    // 使用过滤函数获取所有的willSet访问器
    accessorsMatching { $0 == .keyword(.willSet) }
  }

  // 获取所有的didSet访问器
  var didSetAccessors: [AccessorDeclSyntax] {
    // 使用过滤函数获取所有的didSet访问器
    accessorsMatching { $0 == .keyword(.didSet) }
  }

  // 检查变量是否是计算属性
  var isComputed: Bool {
    // 如果有get访问器，则是计算属性
    if !accessorsMatching({ $0 == .keyword(.get) }).isEmpty {
      return true
    } else {
      // 如果绑定列表中有getter访问器，则是计算属性
      return bindings.contains { binding in
        if case .getter = binding.accessorBlock?.accessors {
          return true
        } else {
          return false
        }
      }
    }
  }

  // 检查变量是否是不可变的
  var isImmutable: Bool {
    // 如果绑定指定符是let关键字，则是不可变的
    return bindingSpecifier.tokenKind == .keyword(.let)
  }

  // 检查两个变量声明是否等效
  func isEquivalent(to other: VariableDeclSyntax) -> Bool {
    // 如果实例变量性质不同，则不等效
    if isInstance != other.isInstance {
      return false
    }
    // 如果标识符不同，则不等效
    return identifier?.text == other.identifier?.text
  }

  // 获取变量的初始化语句
  var initializer: InitializerClauseSyntax? {
    // 从第一个绑定中获取初始化语句
    bindings.first?.initializer
  }

  // 检查变量声明中是否有特定的宏应用
  func hasMacroApplication(_ name: String) -> Bool {
    // 遍历属性列表，检查每个属性的token
    for attribute in attributes {
      switch attribute {
      case let .attribute(attr):
        // 如果属性的token列表包含指定的宏名，则返回true
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return true
        }
      default:
        break
      }
    }
    // 如果没有找到指定的宏应用，则返回false
    return false
  }
}

extension TypeSyntax {
  // 获取类型的标识符
  var identifier: String? {
    for token in tokens(viewMode: .all) {
      switch token.tokenKind {
      case let .identifier(identifier):
        return identifier
      default:
        break
      }
    }
    return nil
  }

  // 对泛型类型进行替换
  func genericSubstitution(_ parameters: GenericParameterListSyntax?) -> String? {
    var genericParameters = [String: TypeSyntax?]()
    if let parameters {
      for parameter in parameters {
        genericParameters[parameter.name.text] = parameter.inheritedType
      }
    }
    var iterator = asProtocol(TypeSyntaxProtocol.self).tokens(viewMode: .sourceAccurate).makeIterator()
    guard let base = iterator.next() else {
      return nil
    }

    if let genericBase = genericParameters[base.text] {
      if let text = genericBase?.identifier {
        return "some " + text
      } else {
        return nil
      }
    }
    var substituted = base.text

    while let token = iterator.next() {
      switch token.tokenKind {
      case .leftAngle:
        substituted += "<"
      case .rightAngle:
        substituted += ">"
      case .comma:
        substituted += ","
      case let .identifier(identifier):
        let type: TypeSyntax = "\(raw: identifier)"
        guard let substituedType = type.genericSubstitution(parameters) else {
          return nil
        }
        substituted += substituedType
      default:
        // ignore?
        break
      }
    }

    return substituted
  }
}

extension FunctionDeclSyntax {
  // 检查函数是否是实例函数
  var isInstance: Bool {
    for modifier in modifiers {
      for token in modifier.tokens(viewMode: .all) {
        if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
          return false
        }
      }
    }
    return true
  }

  // 函数签名的占位符
  struct SignatureStandin: Equatable {
    var isInstance: Bool
    var identifier: String
    var parameters: [String]
    var returnType: String
  }

  // 获取函数的签名占位符
  var signatureStandin: SignatureStandin {
    var parameters = [String]()
    for parameter in signature.parameterClause.parameters {
      parameters.append(parameter.firstName.text + ":" + (parameter.type.genericSubstitution(genericParameterClause?.parameters) ?? ""))
    }
    let returnType = signature.returnClause?.type.genericSubstitution(genericParameterClause?.parameters) ?? "Void"
    return SignatureStandin(isInstance: isInstance, identifier: name.text, parameters: parameters, returnType: returnType)
  }

  // 检查函数是否与其他函数等效
  func isEquivalent(to other: FunctionDeclSyntax) -> Bool {
    return signatureStandin == other.signatureStandin
  }
}

extension AttributeSyntax {
  /// 检查当前属性是否是"available"属性
  var availability: AttributeSyntax? {
    // 如果当前属性的名称是"available", 则返回当前属性
    if attributeName.identifier == "available" {
      return self
    } else {
      // 否则返回nil
      return nil
    }
  }
}

// 扩展IfConfigClauseSyntax.Elements以添加一个检查当前元素是否是"available"属性的方法
extension IfConfigClauseSyntax.Elements {
  var availability: IfConfigClauseSyntax.Elements? {
    // 根据当前元素的类型进行switch
    switch self {
    case let .attributes(attributes):
      // 如果当前元素是属性列表，则检查属性列表中是否有"available"属性
      if let availability = attributes.availability {
        // 如果有，则返回包含该属性的元素
        return .attributes(availability)
      } else {
        // 如果没有，则返回nil
        return nil
      }
    default:
      // 如果当前元素不是属性列表，则返回nil
      return nil
    }
  }
}

// 扩展IfConfigClauseSyntax以添加一个检查当前语句是否是"available"属性的方法
extension IfConfigClauseSyntax {
  var availability: IfConfigClauseSyntax? {
    // 检查当前语句的元素是否是"available"属性
    if let availability = elements?.availability {
      // 如果是，则返回包含该属性的语句
      return with(\.elements, availability)
    } else {
      // 如果不是，则返回nil
      return nil
    }
  }

  // 添加一个方法，用于将当前语句克隆为一个以"if"开头的语句
  var clonedAsIf: IfConfigClauseSyntax {
    // 使用detached方法将当前语句的poundKeyword替换为"if"的token
    detached.with(\.poundKeyword, .poundIfToken())
  }
}

// 扩展IfConfigDeclSyntax以添加一个检查当前声明是否是"available"属性的方法
extension IfConfigDeclSyntax {
  var availability: IfConfigDeclSyntax? {
    // 初始化一个空的元素列表
    var elements = [IfConfigClauseListSyntax.Element]()
    // 遍历当前声明的所有子句
    for clause in clauses {
      // 检查每个子句是否是"available"属性
      if let availability = clause.availability {
        // 如果是，则将其添加到元素列表中
        if elements.isEmpty {
          // 如果元素列表为空，则将克隆后的子句添加到列表中
          elements.append(availability.clonedAsIf)
        } else {
          // 如果元素列表不为空，则直接添加子句
          elements.append(availability)
        }
      }
    }
    // 如果元素列表为空，则返回nil
    if elements.isEmpty {
      return nil
    } else {
      // 如果元素列表不为空，则返回包含这些元素的声明
      return with(\.clauses, IfConfigClauseListSyntax(elements))
    }
  }
}

// 扩展AttributeListSyntax.Element以添加一个检查当前元素是否是"available"属性的方法
extension AttributeListSyntax.Element {
  var availability: AttributeListSyntax.Element? {
    // 根据当前元素的类型进行switch
    switch self {
    case let .attribute(attribute):
      // 如果当前元素是属性，则检查该属性是否是"available"属性
      if let availability = attribute.availability {
        // 如果是，则返回包含该属性的元素
        return .attribute(availability)
      }
    case let .ifConfigDecl(ifConfig):
      // 如果当前元素是ifConfig声明，则检查该声明是否是"available"属性
      if let availability = ifConfig.availability {
        // 如果是，则返回包含该声明的元素
        return .ifConfigDecl(availability)
      }
//    default:
//      // 如果当前元素不是属性或ifConfig声明，则返回nil
//      break
    }
    // 如果当前元素不是"available"属性，则返回nil
    return nil
  }
}

// 扩展AttributeListSyntax以添加一个检查当前列表是否包含"available"属性的方法
extension AttributeListSyntax {
  var availability: AttributeListSyntax? {
    // 初始化一个空的元素列表
    var elements = [AttributeListSyntax.Element]()
    // 遍历当前列表的所有元素
    for element in self {
      // 检查每个元素是否是"available"属性
      if let availability = element.availability {
        // 如果是，则将其添加到元素列表中
        elements.append(availability)
      }
    }
    // 如果元素列表为空，则返回nil
    if elements.isEmpty {
      return nil
    } else {
      // 如果元素列表不为空，则返回包含这些元素的列表
      return AttributeListSyntax(elements)
    }
  }
}
