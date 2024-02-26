import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(LocalizingMacros)
import LocalizingMacros

let testMacros: [String: Macro.Type] = [
    "LocalizedStrings": LocalizedStringsMacro.self,
]
#endif

final class LocalizingTests: XCTestCase {
    func testMacro() throws {
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

                static let key1 =  NSLocalizedString("about_key1", tableName: defaultTableName, bundle: defaultBundle, value: "Localized value 1", comment: "")
                static let key2 =  NSLocalizedString("about_key2", tableName: defaultTableName, bundle: defaultBundle, value: "Localized value 2", comment: "")
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
