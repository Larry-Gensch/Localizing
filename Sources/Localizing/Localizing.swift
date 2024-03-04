//
//  Localizing.swift
//  Localizing
//
//  Created by Larry Gensch on 2/14/24.
//  Copyright © 2024 by Larry Gensch. All rights reserved.

import Foundation

/// Use this macro to create localizable strings that are easily accessed within
/// your code base.
///
/// ## Parameters
///
/// - prefix: The prefix to use for generating localization keys. If omitted, all the key names
///   will be generated without a prefix.
/// - separator: A separator to use between the `prefix` value (if supplied) and the
///   generated key
///
/// > Warning: When this package is upgraded to 1.0.0, **the default separator will be changed from underscore (\_)
/// to a dot (.)**. As such, for users of version 0.9.x, a diagnostic warning will be emitted whenever
/// a prefix is supplied without a separator that suggests adding a separator parameter to the macro call.
/// This diagnostic will be removed in versions 1.0.0 of this package.
///
/// - table: The name of the Localization file to be used for accessing the localizations. If omitted,
///   this defaults to `nil`, which means the base name of the filename will be `Localized`.
/// - bundle: The bundle to be used for retrieving the localizations.
/// - stringsEnum: The name of the inner enumeration that details the base keys and default values
///   for the localization. If `nil`, defaults to the name `Strings`.
///
/// Simply prefix an `enum` with the `@LocalizedStrings()` macro (that may be
/// called with optional parameters menioned above). Within this `enum`, create another  `enum`
/// within it called `Strings`  (with a `RawValue` type `String`).
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
/// So, if the prefix is `"Screens.main"`, a good separator to use might be the dot (`.`).
/// By default, for versions 0.9.x, the separator is an underscore (`_`).
/// This will change in 1.0.0 to dot (`.`).
///
/// The `stringsEnum` specifies the name of an `enum` with a `RawValue` of type `String`. The cases
/// within this enumeration are used to specify the base localization key ((`case` name) and the `rawValue`
/// will be specified as the  default vallue that will used for creating localization constants.
///
/// Once the macro is set up, it will generate constants within the enumeration it is applied
/// to. These constants will map to constants of type `NSLocalizedString` with the following format
/// (with newlines in the example output added for readability)
///
/// ```
/// static let key1 = String(localized: "key1",
///                          defaultValue: "Localized value 1",
///                          table: nil,
///                          bundle: .main)
/// ```
///
/// - term `name`: A case name found in the `stringsEnum` enumeration
/// - term `keyName`: The name of the localization entry, optionally prefixed with the `prefix:`
/// and `separator:` passed to the `@LocalizedStrings()` macro.
/// - term `defaultValue`: The `rawValue` found in the `stringsEnum` enumeration
/// - term `tableName`: Defaults to `nil`, but can be overridden by using the `table:` parameter
/// passed to the `@LocalizedStrings()` macro.
/// - term `bundle`: Defaults to `.main`, but can be overridden by the `bundle:` parameter
/// passed to the `@LocalizedStrings()` macro.
///
/// ## An example
///
/// ```swift
/// @LocalizedStrings(prefix: "main", table: "tbl")
/// enum L {
///     private enum Strings: String {
///         case key1 = "localized value 1"
///         case key2 = "localized value 2"
///     }
/// }
/// ```
/// This generates the following:
/// ```swift
/// enum L {
///     private enum Strings: String {
///         case key1 = "localized value 1"
///         case key2 = "localized value 2"
///     }
///     static let key1 = NSLocalizedString("main_key1", tableName: "tbl", bundle: .main, value: "Localized value 1", comment: "")
///
///     static let key1 = LocalizedStringResource("main_key1", defaultValue: "localized value 1", table: "tbl"", bundle: .main)
///
///     static let key1 = LocalizedStringResource("main_key2", defaultValue: "localized value 2", table: "tbl"", bundle: .main)

/// }
/// ```
///
/// ## Xcode autogeneration
///
/// The parser used by Xcode to build Swift sources will automatically generate entries in the default
/// strings catalog when it encounters values of type `NSLocalizedString()`, `String(localized:)`
/// and `LocalizedStringKey`.
///
/// Unfortunately, this autogeneration does not seem to apply to code generated by macros. This may either
/// be due to a deliberate decision for Xcode not to do this, or may be something that will be added at a
/// future date.
///
/// As a workaround, simply use the `Expand macro` feature in Xcode to show the generated 
/// `NSLocalizedString()`s. The values for the `keyValue` and `value` Strings in the
/// generated code can be used to cut/paste into your strings catalog.
///
@attached(member, names: arbitrary)
public macro LocalizedStrings(prefix: String? = nil,
                              separator: String? = nil,
                              table: String? = nil,
                              bundle: LocalizedStringResource.BundleDescription? = nil,
                              stringsEnum: String? = nil) = #externalMacro(
    module: "LocalizingMacros",
    type: "LocalizedStringsMacro"
)

