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
            @LocalizedStrings(prefix: "about")
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

                static let key1 = NSLocalizedString("about_key1", tableName: nil, bundle: .main, value: "Localized value 1", comment: "")

                static let key2 = NSLocalizedString("about_key2", tableName: nil, bundle: .main, value: "Localized value 2", comment: "")
            }

            extension L: LocalizedStrings {
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

                static let key1 = NSLocalizedString("about_key1", tableName: "tbl", bundle: .main, value: "Localized value 1", comment: "")

                static let key2 = NSLocalizedString("about_key2", tableName: "tbl", bundle: .main, value: "Localized value 2", comment: "")
            }

            extension L: LocalizedStrings {
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

                static let key1 = NSLocalizedString("key1", tableName: nil, bundle: .main, value: "Localized value 1", comment: "")

                static let key2 = NSLocalizedString("key2", tableName: nil, bundle: .main, value: "Localized value 2", comment: "")

                static let key3 = NSLocalizedString("key3", tableName: nil, bundle: .main, value: "key3", comment: "")
            }

            extension L: LocalizedStrings {
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

                static let key1 = NSLocalizedString("key1", tableName: nil, bundle: .main, value: "Localized value 1", comment: "")

                static let key2 = NSLocalizedString("key2", tableName: nil, bundle: .main, value: "Localized value 2", comment: "")

                static let key3 = NSLocalizedString("key3", tableName: nil, bundle: .main, value: "key3", comment: "")
            }

            extension L: LocalizedStrings {
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

                static let key1 = NSLocalizedString("Screens.MainScreen.key1", tableName: nil, bundle: .main, value: "Localized value 1", comment: "")

                static let key2 = NSLocalizedString("Screens.MainScreen.key2", tableName: nil, bundle: .main, value: "Localized value 2", comment: "")

                static let key3 = NSLocalizedString("Screens.MainScreen.key3", tableName: nil, bundle: .main, value: "key3", comment: "")
            }

            extension L: LocalizedStrings {
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

                static let key1 = NSLocalizedString("key1", tableName: nil, bundle: .main, value: "Localized value 1", comment: "")

                static let key2 = NSLocalizedString("key2", tableName: nil, bundle: .main, value: "Localized value 2", comment: "")

                static let key3 = NSLocalizedString("key3", tableName: nil, bundle: .main, value: "key3", comment: "")
            }

            extension L: LocalizedStrings {
            }
            """,

            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }


}
