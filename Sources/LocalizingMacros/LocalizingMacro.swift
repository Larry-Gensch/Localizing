import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LocalizedStringsMacro: MemberMacro {
    enum C {
        static let defsEnum = "Strings"
        static let prefixVariable = "prefix"
        static func localizedStringTemplate(name: String,
                                            key: String,
                                            quotedValue: String,
                                            comment: String) -> String {
            return [
                "static let \(name) = ",
                "NSLocalizedString(\"\(key)\",",
                "tableName: defaultTableName,",
                "bundle: defaultBundle,",
                "value: \(quotedValue),",
                "comment: \"\(comment)\")"
            ]
                .joined(separator: " ")

        }
    }
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw LocalizedStringsError.appliesOnlyToEnumerations
        }

        var prefix: String?

        if let arg = enumDecl.attributes
            .first?.as(AttributeSyntax.self)?
            .arguments?.as(LabeledExprListSyntax.self)?
            .first {
            if case let .identifier(name) = arg.label?.tokenKind,
               name == C.prefixVariable {
                guard let expr = arg.expression.as(StringLiteralExprSyntax.self)
                else {
                    throw LocalizedStringsError.simplePrefix
                }
                prefix = expr.segments.first?.description
            }
        }

        guard let stringsDecl = enumDecl
            .memberBlock
            .members
            .compactMap({ $0.decl.as(EnumDeclSyntax.self) })
            .first(where: { $0.name.text == C.defsEnum })
        else {
            throw LocalizedStringsError.noStringsEnumFound
        }

        let resources = stringsDecl.memberBlock
            .members
            .compactMap {
                $0.decl.as(EnumCaseDeclSyntax.self)?
                    .elements
                    .map {
                        let name = $0.name.text
                        let fixedName = $0.name.text.replacingOccurrences(of: "`", with: "")

                        let key: String = if let prefix {
                            prefix + "_" + fixedName
                        }
                        else {
                            fixedName
                        }
                        let value = $0.rawValue?.value.description ?? name
                        let comment = ""
                        return C.localizedStringTemplate(name: name,
                                                         key: key,
                                                         quotedValue: value,
                                                         comment: comment)
                    }
            }
            .flatMap { $0 }
            .joined(separator: "\n")

        return [DeclSyntax(stringLiteral: resources)]
    }

    enum LocalizedStringsError: String, Error {
        case appliesOnlyToEnumerations = "@LocalizedStrings only applies only to enumerations"
        case noStringsEnumFound = "@LocalizedStrings requires your enum contain an embedded Strings enum"
        case simplePrefix = "@LocalizedStrings requires its 'prefix' parameter to be a simple String value"
    }
}

extension LocalizedStringsMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        return try [ExtensionDeclSyntax("extension \(type.trimmed): LocalizedStrings",
                                        membersBuilder: {
        })]
    }
}
@main
struct LocalizingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LocalizedStringsMacro.self,
    ]
}
