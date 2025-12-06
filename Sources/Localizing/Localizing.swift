//
//   Localizing.swift
//   Localizing
//
//   Created by Larry Gensch on 2/14/24.
//   Copyright © 2024 by Larry Gensch. All rights reserved.

import Foundation

/// Use this macro to create localizable strings that are easily accessed within
/// your source code and automatically updating into an existing string catalog
/// when your code is built.
///
/// ## Parameters
///
/// - Parameter prefix: The prefix to use for generating localization keys. If omitted, all the key names will be generated without a prefix.
/// - Parameter separator: A separator to use between the `prefix` value (if supplied) and the generated key.
/// - Parameter table: The name of the Localization file to be used for accessing the localizations. If omitted,
///   this defaults to `nil`, which means the base name of the filename will be `Localized`.
/// - Parameter bundle: The bundle to be used for retrieving the localizations.
/// - Parameter stringsEnum: The name of the inner enumeration that details the base keys and default values
///   for the localization. If `nil`, defaults to the name `Strings`.
///
/// > Info: The `table` and `bundle` parameters will be omitted from the macro expansion if they
/// are not specified in the macro call, or if their resulting values are the same as the default (effectively,
/// `nil` for `table` and `.main` for `bundle`.
///
/// > Warning: In addition, the separator must be specified as a quoted string. Do not reference a variable when
/// using the `separator:` parameter with the `@LocalizedStrings` macro.
///
/// Simply prefix an `enum` with the `@LocalizedStrings()` macro (that may be
/// called with optional parameters menioned above). Within this `enum`, create another  `enum`
/// within it called `Strings`  (with a `RawValue` type `String`). The `Strings enum` can be modified
/// to a different name using the `stringsEnum` parameter to the macro.
///
/// Each case in this internal enumeration will contain a localization key (the case name) and its
/// associated `rawValue` (default value).
///
/// > Tip: The name `Strings` can be modified using the `stringsEnum:` parameter to the
/// `@LocalizedStrings()` macro.
///
/// ## Symbol Generation
///
/// The `prefix:` and `separator:` parameters to the `@LocalizedStrings` macro are
/// used to give some organization to the localization files. For example, for a
/// SwiftUI project, you might want to use prefixes to specify where the
/// localization is used. Such an example might be `"Screens.main"` to specify that
/// the localizations pertain to the `main` screen in the app. All generated
/// localizations for the associated `enum` will use that prefix (along with
/// the `separator:`) to generate the localization key.
///
/// The `separator:` parameter to the `@LocalizedStrings` macro is used to provide a separator
/// that will be inserted between the `prefix:` value and the generated localization key.
/// So, if the prefix is `"Screens.main"`, a good separator to use might be the dot (`"."`),
/// which also happens to be the default as of version 1.0.0. In previous (beta) versions, the default
/// separator was an underscore (`"-"`).
///
/// The `stringsEnum` specifies the name of an `enum` with a `RawValue` of type `String`. The cases
/// within this enumeration are used to specify the base localization key ((`case` name) and the `rawValue`
/// will be specified as the value that will used for creating the default localization constants.
///
/// Once the macro is set up, it will generate constants within the enumeration it is applied
/// to. These constants will map to constants of type `String(localized:)` with the following format
/// (with newlines in the example output added for readability)
///
/// ```
/// static let key1 = String(localized: "prefix.key1",
///                          defaultValue: "Localized value 1",
///                          table: nil,
///                          bundle: .main,
///                          comment: nil)
/// ```
///
/// - term `name`: A case name found in the `stringsEnum` enumeration
/// - term `keyName`: The name of the localization entry, optionally prefixed with the `prefix:`
/// and `separator:` passed to the `@LocalizedStrings()` macro.
/// - term `defaultValue`: The `rawValue` found in the `stringsEnum` enumeration
/// - term `tableName`: Defaults to `nil` (and omitted), but can be overridden by using the `table:` parameter
/// passed to the `@LocalizedStrings()` macro.
/// - term `bundle`: Defaults to `.main` (and omitted), but can be overridden by the `bundle:` parameter
/// passed to the `@LocalizedStrings()` macro.
/// - term `comment`: Defaults to `nil` (and omitted). Any comment desired for a particular localization key
/// should precede the `case` key for the localization. Multiline C-style comments (`/* ... */`) and
/// mulltiple line comments (`// ...`) are supported, and generate comments with newlines inserted between
/// the lines.
///
/// ## An example
///
/// ```swift
/// @LocalizedStrings(prefix: "about", separator: ".")
/// enum L {
///     private enum Strings: String {
///         // line 1 for key1
///         // line 2 for key1
///         case key1 = "Localized value 1"
///         // single line comment for key2
///         case key2 = "Localized value 2"
///         /* one line C-comment */
///         case key3 = "Localized value 3"
///         /*
///          multiline coment 1 for value 4
///          multiline coment 2 for value 4
///          */
///         case key4 = "Localized value 4"
///         /*
///          single multiline comment 1 for value 5
///          */
///         case key5 = "String arg 5: %@"
///         case key6 = "String arg 6: %@"
///     }
/// }
/// ```
/// This generates the following:
/// ```swift
/// enum L {
///     private enum Strings: String {
///         // line 1 for key1
///         // line 2 for key1
///         case key1 = "Localized value 1"
///         // single line comment for key2
///         case key2 = "Localized value 2"
///         /* one line C-comment */
///         case key3 = "Localized value 3"
///         /*
///          multiline coment 1 for value 4
///          multiline coment 2 for value 4
///          */
///         case key4 = "Localized value 4"
///         /*
///          single multiline comment 1 for value 5
///          */
///         case key5 = "String arg 5: %@"
///         case key6 = "String arg 6: %@"
///     }
/// 
///     static let key1 = String(localized: "about.key1", defaultValue: "Localized value 1", comment: \(multiLineComment)
///                              line 1 for key1
///                              line 2 for key1
///                              \(multiLineComment))
/// 
///     static let key2 = String(localized: "about.key2", defaultValue: "Localized value 2", comment: "single line comment for key2")
/// 
///     static let key3 = String(localized: "about.key3", defaultValue: "Localized value 3", comment: "one line C-comment")
/// 
///     static let key4 = String(localized: "about.key4", defaultValue: "Localized value 4", comment: \(multiLineComment)
///                              multiline coment 1 for value 4
///                              multiline coment 2 for value 4
///                              \(multiLineComment))
/// 
///     static func key5(_ arg1: String) -> String {
///         let temp = String(localized: "about.key5", defaultValue: "String arg 5: %@", comment: \(multiLineComment)
///                           single multiline comment 1 for value 5
///                           \(multiLineComment))
///         return String(format: temp, arg1)
///     }
/// 
///     static func key6(_ arg1: String) -> String {
///         let temp = String(localized: "about.key6", defaultValue: "String arg 6: %@")
///         return String(format: temp, arg1)
///     }
/// }
/// ```
///
/// ## Xcode autogeneration
///
/// The parser used by Xcode to build Swift sources will automatically generate entries in the default
/// strings catalog when it encounters values of type `NSLocalizedString()`, `String(localized:)`
/// and `LocalizedStringResource`.
///
/// The expansion generated by this macro will be noticed by Xcode, and
/// Xcode will automatically create entries into the appropriate string catalog
/// for you. Thus, you can define and comment your macros within your source
/// code and still be able to generate a strings catalog suitable for translation.
///
/// For more information, consult the `README.md` file in this package.
@attached(member, names: arbitrary)
public macro LocalizedStrings(prefix: String? = nil,
                              separator: String? = nil,
                              table: String? = nil,
                              bundle: Bundle? = nil,
                              stringsEnum: String? = nil) = #externalMacro(
    module: "LocalizingMacros",
    type: "LocalizedStringsMacro"
)
