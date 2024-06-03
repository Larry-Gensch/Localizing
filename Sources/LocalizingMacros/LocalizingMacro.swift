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

        static let templateSeparator = ", "

        static let quote = #"""#
        static let quoteRegex = #/^"(.*)"$/#
        static let backtick = "`"
        static let backtickRegex = #/^`(\w+)`$/#
        static let formatRegex = #/%(?:(?<argnum>\d+)\$)?(?<flags>[-+#0])?(?<width>\d+|\*)?(?:\.(?<precision>\d+|\*))?(?<length>[hljztL]|hh|ll)?(?<specifier>[diuoxXfFeEgGaAcspn@])/#

        static func localizedStringTemplate(name: String,
                                            key: String,
                                            table: String,
                                            bundle: String,
                                            quotedValue: String,
                                            comment: String,
                                            stripStatic: Bool = false) -> String {
            let `static` = stripStatic ? "" : "static "
            var lines = [
                "\(`static`)let \(name) = String(localized: \(key)",
                "defaultValue: \(quotedValue)",
            ]
            if table != C.defaultTable {
                lines.append("table: \(table)")
            }
            if bundle != C.defaultBundle {
                lines.append("bundle: \(bundle)")
            }
            if comment != addQuote(C.defaultComment) {
                lines.append("comment: \(comment)")
            }
            return lines.joined(separator: C.templateSeparator) + ")"
        }

        static func localizedFunctionTemplate(name: String,
                                              args: [String],
                                              key: String,
                                              table: String,
                                              bundle: String,
                                              quotedValue: String,
                                              comment: String) -> String {
            let argsString = args.joined(separator: ", ")
            let formatArgs = args.enumerated()
                .map { (index, _) in
                    "arg\(index+1)"
                }
                .joined(separator: ", ")

            let lines = [
                "static func \(name)(\(argsString)) -> String {",
                "    " + localizedStringTemplate(name: "temp",
                                                 key: key,
                                                 table: table,
                                                 bundle: bundle,
                                                 quotedValue: quotedValue,
                                                 comment: comment,
                                                 stripStatic: true),
                "    return String(format: temp, \(formatArgs))",
                "}"
            ]
            return lines.joined(separator: "\n")

        }
    }

    static func parseArgs(unquotedValue: String) throws -> [String] {
        let matches = unquotedValue.matches(of: C.formatRegex)
        guard !matches.isEmpty else { return [] }

        struct FormatResult {
            var index: Int
            var length: String?
            var specifier: String
        }

        var formatResult = [FormatResult]()

        var isUsingIndex: Bool?

        try matches.enumerated().forEach { (index, match) in
            let argnum: Int? = if let value = match.argnum {
                Int(value)
            }
            else {
                nil
            }
            if let isUsingIndex {
                if argnum != nil {
                    throw LocalizedStringsError.stringFormatMissingIndex
                }
            }
            else {
                isUsingIndex = argnum != nil
            }

            let length: String? = if let value = match.output.length {
                String(value)
            }
            else {
                nil
            }
            let specifier: String = String(match.output.specifier)

            let result = FormatResult(index: argnum ?? index + 1,
                                      length: length,
                                      specifier: specifier)
            formatResult.append(result)
        }

        formatResult.sort {
            $0.index < $1.index
        }

        var args = [String]()

        var lastIndex: Int?

        try formatResult.forEach { result in
            if let index = lastIndex {
                if result.index == index {
                    return
                }
                else if result.index == index + 1 {
                    lastIndex = result.index
                }
                else {
                    throw LocalizedStringsError.stringFormatIndexOutOfRange
                }
            }
            else if result.index != 1 {
                throw LocalizedStringsError.stringFormatIndexOutOfRange
            }
            else {
                lastIndex = result.index
            }
            var typeName: String

            switch (result.length, result.specifier) {
            case (nil, "c"):
                typeName = "Character"
            case ("h", "i"), ("h", "x"), ("h", "o"),
                (nil, "i"), (nil, "x"), (nil, "o"):
                typeName = "Int16"
            case ("h", "u"):
                typeName = "UInt16"
            case ("l", "i"), ("l", "x"), ("l", "o"), ("l", "d"),
                ("ll", "i"), ("ll", "x"), ("ll", "o"), ("ll", "d"):
                typeName = "Int"
            case ("l", "u"), ("ll", "u"):
                typeName = "UInt"
            case (nil, "f"), (nil, "e"), (nil, "g"), (nil, "a"):
                typeName = "Double"
            case (nil, "@"):
                typeName = "String"
            default:
                let length = result.length ?? ""
                let specifier = length + result.specifier
                throw LocalizedStringsError.unknownStringFormatSpecifier(specifier)
            }

            args.append("_ arg\(result.index): \(typeName)")
        }

        return args
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

        let resources = try stringsDecl.memberBlock
            .members
            .compactMap {
                try $0.decl.as(EnumCaseDeclSyntax.self)?
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
                        let args = try parseArgs(unquotedValue: removeQuotes(value) ?? "")
                        if args.isEmpty {
                            return C.localizedStringTemplate(name: safeName,
                                                             key: keyQuoted,
                                                             table: table,
                                                             bundle: bundle,
                                                             quotedValue: value,
                                                             comment: comment)
                        }
                        else {
                            return C.localizedFunctionTemplate(name: safeName,
                                                               args: args,
                                                               key: keyQuoted,
                                                               table: table,
                                                               bundle: bundle,
                                                               quotedValue: value,
                                                               comment: comment)
                        }
                    }
            }
            .flatMap { $0 }
            .map { DeclSyntax(stringLiteral: $0) }

        return resources
    }

    public enum LocalizedStringsError: LocalizedError {
        case parserError
        case appliesOnlyToEnumerations
        case noStringsEnumFound
        case simpleParameter
        case stringFormatMissingIndex
        case stringFormatIndexOutOfRange
        case unknownStringFormatSpecifier(String)

        public var errorDescription: String? {
            switch self {
            case .parserError:  return "Parser error"
            case .appliesOnlyToEnumerations:  return "@LocalizedStrings only applies only to enumerations"
            case .noStringsEnumFound:  return "@LocalizedStrings requires your enum contain an embedded Strings enum"
            case .simpleParameter:  return "@LocalizedString requires its parameters to be a simple String value"
            case .stringFormatMissingIndex:  return "String format parameters must either all use or none use index paramters"
            case .stringFormatIndexOutOfRange:  return "String format parameter index duplicated, missing, or out of range"
            case .unknownStringFormatSpecifier(let s):  return "Unknown string format specifier: \(s)"

            }
        }
    }
}

@main
struct LocalizingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LocalizedStringsMacro.self,
    ]
}
