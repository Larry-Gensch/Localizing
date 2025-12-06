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
    func testComments() throws {
#if canImport(LocalizingMacros)
        let multiLineComment = String(String(repeating: "\"", count: 3))
        assertMacroExpansion(
            """
            @LocalizedStrings(prefix: "about", separator: ".")
            enum L {
                private enum Strings: String {
                    // line 1 for key1
                    // line 2 for key1
                    case key1 = "Localized value 1"
                    // single line comment for key2
                    case key2 = "Localized value 2"
                    /* one line C-comment */
                    case key3 = "Localized value 3"
                    /*
                     multiline coment 1 for key 4
                     multiline coment 2 for key 4
                    */
                    case key4 = "Localized value 4"
                    /*
                     single multiline comment 1 for key 5
                    */
                    case key5 = "String arg 5: %@"
                    case key6 = "String arg 6: %@"
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    // line 1 for key1
                    // line 2 for key1
                    case key1 = "Localized value 1"
                    // single line comment for key2
                    case key2 = "Localized value 2"
                    /* one line C-comment */
                    case key3 = "Localized value 3"
                    /*
                     multiline coment 1 for key 4
                     multiline coment 2 for key 4
                    */
                    case key4 = "Localized value 4"
                    /*
                     single multiline comment 1 for key 5
                    */
                    case key5 = "String arg 5: %@"
                    case key6 = "String arg 6: %@"
                }
            
                static let key1 = String(
                    localized: "about.key1",
                    defaultValue: "Localized value 1",
                    comment: \(multiLineComment)
                line 1 for key1
                line 2 for key1
                \(multiLineComment)
                )
            
                static let key2 = String(
                    localized: "about.key2",
                    defaultValue: "Localized value 2",
                    comment: "single line comment for key2"
                )
            
                static let key3 = String(
                    localized: "about.key3",
                    defaultValue: "Localized value 3",
                    comment: "one line C-comment"
                )
            
                static let key4 = String(
                    localized: "about.key4",
                    defaultValue: "Localized value 4",
                    comment: \(multiLineComment)
                multiline coment 1 for key 4
                multiline coment 2 for key 4
                \(multiLineComment)
                )
            
                static func key5(_ arg1: String) -> String {
                    let temp = String(
                        localized: "about.key5",
                        defaultValue: "String arg 5: %@",
                        comment: \(multiLineComment)
                single multiline comment 1 for key 5
                \(multiLineComment)
                    )
                    return String(format: temp, arg1)
                }
            
                static func key6(_ arg1: String) -> String {
                    let temp = String(
                        localized: "about.key6",
                        defaultValue: "String arg 6: %@"
                    )
                    return String(format: temp, arg1)
                }
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testMacroPrefix() throws {
#if canImport(LocalizingMacros)
        assertMacroExpansion(
            """
            @LocalizedStrings(prefix: "about", separator: ".")
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3 = "String arg: %@"
                }
            }
            """,
            expandedSource:
            """
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3 = "String arg: %@"
                }
            
                static let key1 = String(
                    localized: "about.key1",
                    defaultValue: "Localized value 1"
                )
            
                static let key2 = String(
                    localized: "about.key2",
                    defaultValue: "Localized value 2"
                )
            
                static func key3(_ arg1: String) -> String {
                    let temp = String(
                        localized: "about.key3",
                        defaultValue: "String arg: %@"
                    )
                    return String(format: temp, arg1)
                }
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
            
                static let key1 = String(
                    localized: "key1",
                    defaultValue: "Localized value 1",
                    table: "tbl"
                )
            
                static let key2 = String(
                    localized: "key2",
                    defaultValue: "Localized value 2",
                    table: "tbl"
                )
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
            
                static let key1 = String(
                    localized: "key1",
                    defaultValue: "Localized value 1"
                )
            
                static let key2 = String(
                    localized: "key2",
                    defaultValue: "Localized value 2"
                )
            
                static let key3 = String(
                    localized: "key3",
                    defaultValue: "key3"
                )
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
            
                static let key1 = String(
                    localized: "key1",
                    defaultValue: "Localized value 1"
                )
            
                static let key2 = String(
                    localized: "key2",
                    defaultValue: "Localized value 2"
                )
            
                static let key3 = String(
                    localized: "key3",
                    defaultValue: "key3"
                )
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
            
                static let key1 = String(
                    localized: "Screens.MainScreen.key1",
                    defaultValue: "Localized value 1"
                )
            
                static let key2 = String(
                    localized: "Screens.MainScreen.key2",
                    defaultValue: "Localized value 2"
                )
            
                static let key3 = String(
                    localized: "Screens.MainScreen.key3",
                    defaultValue: "key3"
                )
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testMainBundle() throws {
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
            
                static let key1 = String(
                    localized: "key1",
                    defaultValue: "Localized value 1"
                )
            
                static let key2 = String(
                    localized: "key2",
                    defaultValue: "Localized value 2"
                )
            
                static let key3 = String(
                    localized: "key3",
                    defaultValue: "key3"
                )
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }


    func testOtherBundle() throws {
#if canImport(LocalizingMacros)

        assertMacroExpansion(
            """
            @objc class SomeClass: NSObject { }
            let bundle = Bundle(for: SomeClass.self)
            
            @LocalizedStrings(bundle: bundle)
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
            @objc class SomeClass: NSObject { }
            let bundle = Bundle(for: SomeClass.self)
            enum L {
                private enum Strings: String {
                    case key1 = "Localized value 1"
                    case key2 = "Localized value 2"
                    case key3
                }
            
                static let key1 = String(
                    localized: "key1",
                    defaultValue: "Localized value 1",
                    bundle: bundle
                )
            
                static let key2 = String(
                    localized: "key2",
                    defaultValue: "Localized value 2",
                    bundle: bundle
                )
            
                static let key3 = String(
                    localized: "key3",
                    defaultValue: "key3",
                    bundle: bundle
                )
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
            
                static let `class` = String(
                    localized: "class",
                    defaultValue: "Localized value 1"
                )
            
                static let `associatedtype` = String(
                    localized: "associatedtype",
                    defaultValue: "Localized value 2"
                )
            
                static let key3 = String(
                    localized: "key3",
                    defaultValue: "key3"
                )
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
