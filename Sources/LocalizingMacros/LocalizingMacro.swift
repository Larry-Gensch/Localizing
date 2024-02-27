import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LocalizedStringsMacro: MemberMacro {
    enum C {
        static let defaultEnum = "Strings"
        static let defaultSeparator = "_"

        static func localizedStringTemplate(name: String,
                                            key: String,
                                            table: String?,
                                            bundle: String,
                                            quotedValue: String,
                                            comment: String) -> String {
            let table = table ?? "nil"

            return [
                "static let \(name) =",
                "NSLocalizedString(\(key),",
                "tableName: \(table),",
                "bundle: \(bundle),",
                "value: \(quotedValue),",
                "comment: \"\(comment)\")"
            ]
                .joined(separator: " ")

        }
    }

    enum Variables: String, CaseIterable, Hashable {
        case prefix
        case table
        case separator
        case stringsEnum
        case bundle

        
        var type: Any {
            switch self {
            case .bundle: Bundle.self
            default: StringLiteralExprSyntax.self
            }
        }

        var name: String { rawValue }
    }

    private static func extractArgs(from args: LabeledExprListSyntax) -> [Variables: String] {
        args.reduce(into: [:]) { partialResult, arg in
            if case .identifier(let value) = arg.label?.tokenKind,
               let variable = Variables(rawValue: value) {
                partialResult[variable] = arg.expression.description
            }
        }
    }

    private static func dequote(_ string: String?) -> String? {
        string?
            .replacing(#/^"(.*)"$/#) { match in
                match.output.1
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

        var variables = [Variables: String]()

        if let args = enumDecl.attributes
            .first?.as(AttributeSyntax.self)?
            .arguments?.as(LabeledExprListSyntax.self) {
            variables = extractArgs(from: args)
        }


        let prefix = dequote(variables[.prefix])

        let table = variables[.table]
        let bundle = variables[.bundle] ?? ".main"
        let separator = dequote(variables[.separator]) ?? C.defaultSeparator
        let stringsEnum = dequote(variables[.stringsEnum]) ?? C.defaultEnum

        guard let stringsDecl = enumDecl
            .memberBlock
            .members
            .compactMap({ $0.decl.as(EnumDeclSyntax.self) })
            .first(where: { $0.name.text == stringsEnum })
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
                            prefix + separator + fixedName
                        }
                        else {
                            fixedName
                        }
                        let keyQuoted = "\"\(key)\""
                        let value = $0.rawValue?.value.description ?? "\"\(name)\""
                        let comment = ""
                        return C.localizedStringTemplate(name: name,
                                                         key: keyQuoted,
                                                         table: table,
                                                         bundle: bundle,
                                                         quotedValue: value,
                                                         comment: comment)
                    }
            }
            .flatMap { $0 }
            .map { DeclSyntax(stringLiteral: $0) }

        return resources
    }

    enum LocalizedStringsError: String, Error {
        case appliesOnlyToEnumerations = "@LocalizedStrings only applies only to enumerations"
        case noStringsEnumFound = "@LocalizedStrings requires your enum contain an embedded Strings enum"
        case simpleParameter = "@LocalizedString requires its parameters to be a simple String value"
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
