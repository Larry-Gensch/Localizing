# Localizing

@LocalizedStrings Macro

Use this macro to create localizable strings that are easily accessed within
your code base and automatically updating into an existing string catalog
when your code is built.

## Parameters

- prefix: The prefix to use for generating localization keys. If omitted, all the key names
  will be generated without a prefix.
- separator: A separator to use between the `prefix` value (if supplied) and the
  generated key (see warnings)).
- table: The name of the Localization file to be used for accessing the localizations. If omitted,
  this defaults to `nil`, which means the base name of the filename will be `Localized`.
- bundle: The bundle to be used for retrieving the localizations.
- stringsEnum: The name of the inner enumeration that details the base keys and default values
  for the localization. If `nil`, defaults to the name `Strings`.

> Info: The `table` and `bundle` parameters will be omitted from the macro expansion if they
are not specified in the macro call, or if their resulting values are the same as the default (effectively,
`nil` for `table` and `.main` for `bundle`.

> Warning: When this package is upgraded to 1.0.0, **the default separator will be changed from underscore (\_)
  to a dot (.)**. As such, for users of version 0.9.x, a diagnostic warning will be emitted whenever
  a prefix is supplied without a separator that suggests adding a separator parameter to the macro call.
  This diagnostic will be removed in versions 1.0.0 of this package.
  In addition, the separator must be specified as a quoted string. Do not reference a variable when
  using the `separator:` parameter with the `@LocalizedStrings` macro, as macros run prior to compilation.

Simply prefix an `enum` with the `@LocalizedStrings()` macro (that may be
called with optional parameters menioned above). Within this `enum`, create another  `enum`
within it called `Strings`  (with a `RawValue` type `String`).

Each case in this internal `Strings` enumeration will contain a localization key (the case name) and its
associated `rawValue` (default value). Note that Swift enforces that all enumerations comforming to
`String` have unique values and rawValues.

> Tip: The name `Strings` can be modified using the `stringsEnum:` parameter to the
  `@LocalizedStrings()` macro. I allow this to be overridden, but... why is this necessary???

## Symbol Generation

The `prefix:` and `separator:` parameters to the `@LocalizedStrings` macro are
used to give some organization to the localization files. For example, for a
SwiftUI project, you might want to use prefixes to specify where the
localization is used. Such an example might be `"Screens.main"` to specify that
the localizations pertain to the `main` screen in the app. All generated 
localizations for the associated `enum` will use that prefix (along with 
the `separator:`) to generate the localization key.

The `separator:` parameter to the `@LocalizedStrings` macro is used to provide a separator
that will be inserted between the `prefix:` value and the generated localization key.
So, if the prefix is `"Screens.main"`, a good separator to use might be the dot (`"."`).
By default, for versions 0.9.x, the default separator is an underscore (`"_"`).
This will change in 1.0.0 to dot (`"."`).

The `stringsEnum` specifies the name of an `enum` with a `RawValue` of type `String`. The cases
within this enumeration are used to specify the base localization key ((`case` name) and the `rawValue`
will be specified as the  default vallue that will used for creating localization constants.

Once the macro is set up, it will generate constants within the enumeration it is applied
to. These constants will map to constants of type `String(localized:)` with the following format
(with newlines in the example output added for better readability).

If a comment precedes a `case` in the `Strings enum`, the comment will be supplied to the
`String(localized: ...)` generated localization. Single and multiple line comments are
supported.

```
static let key1 = String(localized: "prefix.key1",
                         defaultValue: "Localized value 1",
                         table: nil,
                         bundle: .main)
```

- term `name`: A case name found in the `stringsEnum` enumeration
- term `keyName`: The name of the localization entry, optionally prefixed with the `prefix:`
and `separator:` passed to the `@LocalizedStrings()` macro.
- term `defaultValue`: The `rawValue` found in the `stringsEnum` enumeration
- term `tableName`: Defaults to `nil` (and omitted), but can be overridden by using the `table:` parameter
passed to the `@LocalizedStrings()` macro.
- term `bundle`: Defaults to `.main` (and omitted), but can be overridden by the `bundle:` parameter
passed to the `@LocalizedStrings()` macro.
- term `comment`: Defaults to `""` (and omitted). This is any comment preceding any `case`
enumeration to the `Strings enum`.

For default values that contain format-style strings (e.g., "%@", or "%lld""), a function is
created instead of a simple property so that values can be supplied. The function is generated
using the correct parameter types (e.g., "String" for "%@" or "Int" for "%lld") for each argument. 
Format strings using positional parameter indices (e.g., "%1$@" or "%2$lld" will ensure that the
parameters are called with the correct indices as well). If a format string cannot be parsed properly
to find the correct parameter type, or is not consistently indexed, or with missing parameter indices,
a compilation error is generated at the function call site. If you think any generated error is 
incorrect, please file an issue at the GitHub repository.

## An example

```swift
@LocalizedStrings(prefix: "about", separator: ".")
enum L {
    private enum Strings: String {
        // mutiple line comment 1 for key1
        // mutiple line comment 2 for key1
        case key1 = "Localized value 1"
        
        // single line comment 1 for key2
        case key2 = "Localized value 2"
        
        /* single line C-comment */
        case key3 = "Localized value 3"
        
        /*
         multiple line coment 1 for value 4
         multiple line comentfor value 4
         */
        case key4 = "Localized value 4"
        
        /*
         indented C-comment line 1 for value 5
         */
        case key5 = "String arg 5: %@"
        case key6 = "String arg 6: %@"
    }
}
```
This generates the following:
```swift
enum L {
    private enum Strings: String {
        // mutiple line comment 1 for key1
        // mutiple line comment 2 for key1
        case key1 = "Localized value 1"

        // single line comment 1 for key2
        case key2 = "Localized value 2"

        /* single line C-comment */
        case key3 = "Localized value 3"

        /*
         multiple line comment 1 for value 4
         */
        case key4 = "Localized value 4"

        case key5 = "String arg 6: %@"
    }
    static let key1 = String(localized: "about.key1",
                             defaultValue: "Localized value 1",
                             comment: """
        line 1 for key1
        line 2 for key1
        """)
    static let key2 = String(localized: "about.key2",
                             defaultValue: "Localized value 2",
                             comment: "line 1 for key2")
    static let key3 = String(localized: "about.key3",
                             defaultValue: "Localized value 3",
                             comment: "one line C-comment")
    static let key4 = String(localized: "about.key4",
                             defaultValue: "Localized value 4",
                             comment: """
        multiline coment 1 for value 4
        multiline coment 2 for value 4
        """)
    static func key5(_ arg1: String) -> String {
        let temp = String(localized: "about.key5",
                          defaultValue: "String arg 5: %@",
                          comment: """
        single multiline comment 1 for value 5
        """)
        return String(format: temp, arg1)
    }
    static func key6(_ arg1: String) -> String {
        let temp = String(localized: "about.key6",
                          defaultValue: "String arg 6: %@")
        return String(format: temp, arg1)
    }
}
```

## Xcode autogeneration

The parser used by Xcode to build Swift sources will automatically generate entries in the default
strings catalog when it encounters values of type `NSLocalizedString()`, `String(localized:)`
and `LocalizedStringResource` as well as some SwiftUI views that use `LocalizedStringKey`.

The expansion generated by this macro will be noticed by Xcode, and
Xcode will automatically create entries into the appropriate string catalog
for you.


## Additional notes

Xcode will notice that a localization item it created has been changed to
manual management. If the localization disappears, it will **not** be auto-removed.
Instead, Xcode will mark the entry as `STALE`. If you see such an entry, you
can manually delete the localization if you want.

## If Xcode autogeneration isn't working

If you find that none, or perhaps only a few localizations are being
autogenerated into your string catalog, ensure you are looking for
the correct file (where localizations are stored are affected by
the `table` and `bundle` parameters passed to the macros), and that
the string catalog has been created and added to your project.

If that doesn't work, check your build settings for your target,
and filter using the word "local" to limit the settings on the
screen mostly to those involving localizations.

In the section `Localizations` ensure that the following values are 
set to `Yes`:

- Localization Export Supported
- Localization Prefers String Catalogs
- Localized String SwiftUI Support
- Use Compiler to Extract Swift Strings

If you needed to change any of the above settings, simply rebuild and 
your localizations should start to export.

In the event that modifying the build settings doesn't work for you,
try removing (or stash) your string catalogs, re-create them, and try
again.
