//
//  LocalizingMacro.swift
//  Localizing
//
//  Created by Larry Gensch on 2/14/24.
//  Copyright © 2024 by Larry Gensch. All rights reserved.

import Foundation
import SwiftUI
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct LocalizedStringsMacro: MemberMacro {
    private enum C {
        static let defaultEnum = "Strings"
        static let defaultSeparator = "_"
        static let defaultTable = "nil"
        static let defaultBundle = ".main"
        static let defaultComment = ""

        static let quote = #"""#
        static let quoteRegex = #/^"(.*)"$/#
        static let backtick = "`"
        static let backtickRegex = #/^`(\w+)`$/#

        static func localizedStringTemplate(name: String,
                                            key: String,
                                            table: String,
                                            bundle: String,
                                            quotedValue: String,
                                            comment: String) -> String {
            [
                "static let \(name) =",
                "String(localized: \(key),",
                "defaultValue: \(quotedValue),",
                "table: \(table),",
                "bundle: \(bundle))",
            ]
                .joined(separator: " ")
        }

        static func nsLocalizedStringTemplate(name: String,
                                              key: String,
                                              table: String,
                                              bundle: String,
                                              quotedValue: String,
                                              comment: String) -> String {
            return [
                "static let \(name) =",
                "NSLocalizedString(\(key),",
                "tableName: \(table),",
                "bundle: \(bundle),",
                "value: \(quotedValue),",
                "comment: \(comment))"
            ]
                .joined(separator: " ")
        }
    }

    enum L {
        static let separatorChanging = NSLocalizedString("separator.warning",
                                                               value: """
            The default separator is changing from '_' to '.' as of version 1.0.0.
            If you wish to keep using the underscore as a separator, it is suggested
            that you add an explicit separator argument to the @LocalizedStrings macro.
            """,
                                                         comment: "")
    }

    private enum Variables: String, CaseIterable, Hashable {
        case prefix
        case table
        case separator
        case stringsEnum
        case bundle
        
        var name: String { rawValue }
    }

    private static func removeQuotes(_ string: String?) -> String? {
        string?
            .replacing(C.quoteRegex) { match in
                match.output.1
            }
    }

    private static func removeBackticks(_ string: String) -> String {
        string
            .replacing(C.backtickRegex) { match in
                match.output.1
            }
    }

    private static func addQuote(_ string: String) -> String {
        C.quote + string + C.quote
    }

    private static func addBacktick(_ string: String) -> String {
        C.backtick + string + C.backtick
    }

    enum WarningDiagnostic: DiagnosticMessage {
        var diagnosticID: SwiftDiagnostics.MessageID {
            switch self {
            case .changing:
                    .init(domain: "org.amber3.macros.Localizing", id: "changing")
            }
        }

        case changing(message: String, severity: DiagnosticSeverity)

        var message: String {
            switch self {
            case .changing(let message, _):
                message
            }
        }

        var severity: DiagnosticSeverity {
            switch self {
            case .changing(_, let severity):
                severity
            }
        }
    }

    private static func extractArgs(from args: LabeledExprListSyntax) -> [Variables: String] {
        args.reduce(into: [:]) { partialResult, arg in
            if case .identifier(let value) = arg.label?.tokenKind,
               let variable = Variables(rawValue: value) {
                partialResult[variable] = arg.expression.description
            }
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

        guard let args = enumDecl.attributes
            .first?.as(AttributeSyntax.self)?
            .arguments?.as(LabeledExprListSyntax.self) else {
            throw LocalizedStringsError.parserError
        }

        let variables = extractArgs(from: args)

        if variables[.separator] == nil,
           variables[.prefix] != nil {
            let diagnostic = WarningDiagnostic.changing(message: L.separatorChanging,
                                                        severity: .warning)
            context.diagnose(Diagnostic(node: node,
                                        message: diagnostic))
        }
        // Set up variable replacements and their defaults
        let prefix = removeQuotes(variables[.prefix])
        let table = variables[.table] ?? C.defaultTable
        let bundle = variables[.bundle] ?? C.defaultBundle
        let separator = removeQuotes(variables[.separator]) ?? C.defaultSeparator
        let stringsEnum = removeQuotes(variables[.stringsEnum]) ?? C.defaultEnum
        let comment = addQuote("")

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
                        let safeName = $0.name.text
                        let name = removeBackticks(safeName)

                        let key = if let prefix {
                            prefix + separator + name
                        }
                        else {
                            name
                        }
                        let keyQuoted = addQuote(key)
                        let value = $0.rawValue?.value.description ?? addQuote(name)
                        return C.localizedStringTemplate(name: safeName,
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

    public enum LocalizedStringsError: String, Error {
        case parserError = "Parser error"
        case appliesOnlyToEnumerations = "@LocalizedStrings only applies only to enumerations"
        case noStringsEnumFound = "@LocalizedStrings requires your enum contain an embedded Strings enum"
        case simpleParameter = "@LocalizedString requires its parameters to be a simple String value"
    }
}

@main
struct LocalizingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LocalizedStringsMacro.self,
    ]
}
