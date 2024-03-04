//
//  LocalizingTests.swift
//  Localizing
//
//  Created by Larry Gensch on 2/14/24.
//  Copyright © 2024 by Larry Gensch. All rights reserved.

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacroExpansion
import SwiftParserDiagnostics
import SwiftParser
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(LocalizingMacros)
import LocalizingMacros

let testMacros: [String: Macro.Type] = [
    "LocalizedStrings": LocalizedStringsMacro.self,
]
#endif

final class LocalizingTests: XCTestCase {
    func testMacroPrefix() throws {
        #if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(prefix: "about", separator: ".")
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                }

                static let key1 = String(localized: "about.key1", defaultValue: "Localized value 1", table: nil, bundle: .main)

                static let key2 = String(localized: "about.key2", defaultValue: "Localized value 2", table: nil, bundle: .main)
            }
            """,

            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroTable() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(table: "tbl")
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                }

                static let key1 = String(localized: "key1", defaultValue: "Localized value 1", table: "tbl", bundle: .main)

                static let key2 = String(localized: "key2", defaultValue: "Localized value 2", table: "tbl", bundle: .main)
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testMacroDefaultRawValue() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings()
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }

                static let key1 = String(localized: "key1", defaultValue: "Localized value 1", table: nil, bundle: .main)

                static let key2 = String(localized: "key2", defaultValue: "Localized value 2", table: nil, bundle: .main)

                static let key3 = String(localized: "key3", defaultValue: "key3", table: nil, bundle: .main)
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testMacroStringsEnum() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(stringsEnum: "Values")
            enum L {
                private enum Values: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Values: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }

                static let key1 = String(localized: "key1", defaultValue: "Localized value 1", table: nil, bundle: .main)

                static let key2 = String(localized: "key2", defaultValue: "Localized value 2", table: nil, bundle: .main)

                static let key3 = String(localized: "key3", defaultValue: "key3", table: nil, bundle: .main)
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testMacroSeparator() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(prefix: "Screens.MainScreen",
                              separator: ".")
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }

                static let key1 = String(localized: "Screens.MainScreen.key1", defaultValue: "Localized value 1", table: nil, bundle: .main)

                static let key2 = String(localized: "Screens.MainScreen.key2", defaultValue: "Localized value 2", table: nil, bundle: .main)

                static let key3 = String(localized: "Screens.MainScreen.key3", defaultValue: "key3", table: nil, bundle: .main)
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testBundle() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(bundle: .main)
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }

                static let key1 = String(localized: "key1", defaultValue: "Localized value 1", table: nil, bundle: .main)

                static let key2 = String(localized: "key2", defaultValue: "Localized value 2", table: nil, bundle: .main)

                static let key3 = String(localized: "key3", defaultValue: "key3", table: nil, bundle: .main)
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testReservedWords() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(bundle: .main)
            enum L {
                private enum Strings: String {
                    case `class` = "Localized value 1"
                    case `associatedtype` = "Localized value 2"
                    case key3
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case `class` = "Localized value 1"
                    case `associatedtype` = "Localized value 2"
                    case key3
                }

                static let `class` = String(localized: "class", defaultValue: "Localized value 1", table: nil, bundle: .main)

                static let `associatedtype` = String(localized: "associatedtype", defaultValue: "Localized value 2", table: nil, bundle: .main)

                static let key3 = String(localized: "key3", defaultValue: "key3", table: nil, bundle: .main)
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testSeparatorDiagnostic() throws {
#if canImport(LocalizingMacros)
        let message = """
            The default separator is changing from '_' to '.' as of version 1.0.0.
            If you wish to keep using the underscore as a separator, it is suggested
            that you add an explicit separator argument to the @LocalizedStrings macro.
            """

        let diagSpec = DiagnosticSpec(message: message,
                                      line: 1,
                                      column: 1,
                                      severity: .warning)
        assertMacroExpansion(
            """
            @LocalizedStrings(prefix: "about", table: "tbl")
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                }

                static let key1 = String(localized: "about_key1", defaultValue: "Localized value 1", table: "tbl", bundle: .main)

                static let key2 = String(localized: "about_key2", defaultValue: "Localized value 2", table: "tbl", bundle: .main)
            }
            """,
            diagnostics: [diagSpec],

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }


}
