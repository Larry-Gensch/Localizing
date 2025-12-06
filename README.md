# Localizing

@LocalizedStrings Macro

Use this macro to create localizable strings that are easily accessed within
your code base and automatically update into an existing string catalog
when your code is built.

## Purpose

The new string catalogs that Xcode automatically updates are useful, but there
are some limitations:

1. It's necessary for a developer to context switch from source code to string
catalog to see the localizations for a key to be used.

2. If a localization value has arguments (eg, "%@"), it needs to be formatted
properly for use.

The `@LocalizedStrings` macro allows the string catalog to be managed from
within the source files that reference various values.

For example, if there are two localized strings to be used in a particular screen,
the macro allows you to specify them in this manner:

```swift
@LocalizedStrings(prefix: "screens.about", separator: ".")
enum L {
    enum Strings: String {
        case copyright = "Copyright©️ 2025, Some Big Shot Corporation"
        // %1$@: Major/Minor version number in format #.#
        // %2$@: Build number
        case version = "Version %1$@.%2$@"
    }
}

When the macro is expanded, it produces something similar to the following:

```swift
enum L {
    enum Strings: String {
        case copyright = "Copyright©️ 2025, Some Big Shot Corporation"
        // %1$@: Major/Minor version number in format #.#
        // %2$@: Build number
        case version = "Version %1$@.%2$@"
    }
    
static let copyright = String(
    localized: "screens.about.copyright",
    defaultValue: "Copyright©️ 2025, Some Big Shot Corporation"
)

static func version(\_ arg1: String) -> String {
    let temp = String(
        localized: "screens.about.version",
        defaultValue: "Version %1$@.%2$@",
        comment: """
    %1$@: Major/Minor version number in format #.#
    %2$@: Build number
    """
    )
    return String(format: temp, arg1)
}
}

Now, to reference any of these symbols, you simply type `L.` and the Xcode editor
can help locate the proper symbol. So, if you type `L.c`, Xcode can offer the `opyright`
following the `c`.

When the code is built, Xcode will synchronize the localizations into the strings
catalog. The keys added or updated will be the following:

- term `screens.about.copyright`: With the English value specified in the `Strings` enumeration and no comment.
- term `screens.about.version`: With the English value specified in the `Strings` enumeration and a 2-line comment.

``` 
## Parameters

The `@LocalizedStrings` macro uses the following parameters:

```
    @LocalizedStrings(
        prefix: String?,
        separator: String?,
        table: String?,
        bundle: Bundle?,
        stringsEnum: String?
    )
```

- prefix: The prefix to use for generating localization keys. If omitted, all the key names
  will be generated without a prefix. This is useful for grouping related localizations.
- separator: A separator to use between the `prefix` value (if supplied) and the
  generated key. If omitted, a period (`.`) will be used.
- table: The name of the Localization file to be used for accessing the localizations. If omitted,
  this defaults to `nil`, which means the base name of the filename will be `Localized`.
- bundle: The bundle to be used for retrieving the localizations. This is useful for localizations
  with frameworks.
- stringsEnum: The name of the inner enumeration that details the base keys and default values
  for the localization. If `nil`, defaults to the name `Strings`.

> Info: The `table` and `bundle` parameters will be omitted from the macro expansion if they
are not specified in the macro call, or if their resulting values are the same as the default (effectively,
`nil` for `table` and `.main` for `bundle`.

Simply prefix an `enum` with the `@LocalizedStrings()` macro (that may be
called with optional parameters menioned above). Within this `enum`, create another  `enum`
within it called `Strings` (with a `RawValue` type `String`).

Each case in this internal `Strings` enumeration will contain a localization key (the case name) and its
associated `rawValue` (default value). Note that Swift enforces that all enumerations comforming to
`String` have unique values and rawValues. If there are comments preceding the case name, these will be
used for the `comments` parameter in the localization.

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
So, if the prefix is `"Screens.main"`, a good separator to use might be the dot (`"."`),
which also happens to be the default as of version 1.0.0. In previous (beta) versions,
the default separator was an underscore (`"-"`).

The `stringsEnum` specifies the name of an `enum` with a `RawValue` of type `String`. The cases
within this enumeration are used to specify the base localization key ((`case` name) and the `rawValue`
will be specified as the value that will used for creating the default localization constants.

Once the macro is set up, it will generate constants within the enumeration it is applied
to. These constants will map to constants of type `String(localized:)` with the following format
(with newlines in the example output added for better readability).

If a comment precedes a `case` in the `Strings enum`, the comment will be supplied to the
`String(localized: ...)` generated localization. Any comment desired for a particular localization key
should precede the `case` key for the localization. Multiline C-style comments (`/* ... */`) and
mulltiple line comments (`// ...`) are supported, and generate comments with newlines inserted between
the lines.

Here is a sample of the generated output:

```
static let key1 = String(
    localized: "prefix.key1",
    defaultValue: "Localized value 1",
    table: nil,
    bundle: .main,
    comment: "Comment for key1"
)
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

For default values that contain format-style strings (e.g., "%@", "%lld", or even "%2$lld"), a function is
created instead of a simple property so that values can be supplied. The function is generated
using the correct parameter types (e.g., "String" for "%@" or "Int" for "%lld") for each argument. 
Format strings using positional parameter indices (e.g., "%1$@" or "%2$lld" will ensure that the
parameters are called with the correct indices as well). If a format string cannot be parsed properly
to find the correct parameter type, or is not consistently indexed, or with missing parameter indices,
a compilation error is generated at the function call site. If you think any generated code or error
diagnostic is incorrect, please file an issue at the GitHub repository.

## An example

```swift
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
             multiline coment 1 for value 4
             multiline coment 2 for value 4
            */
            case key4 = "Localized value 4"
            /*
             single multiline comment 1 for value 5
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
            // line 1 for key1
            // line 2 for key1
            case key1 = "Localized value 1"
            // single line comment for key2
            case key2 = "Localized value 2"
            /* one line C-comment */
            case key3 = "Localized value 3"
            /*
             multiline coment 1 for value 4
             multiline coment 2 for value 4
            */
            case key4 = "Localized value 4"
            /*
             single multiline comment 1 for value 5
            */
            case key5 = "String arg 5: %@"
            case key6 = "String arg 6: %@"
        }

        static let key1 = String(
            localized: "about.key1",
            defaultValue: "Localized value 1",
            comment: """
        line 1 for key1
        line 2 for key1
        """
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
            comment: """
        multiline coment 1 for value 4
        multiline coment 2 for value 4
        """
        )

        static func key5(_ arg1: String) -> String {
            let temp = String(
                localized: "about.key5",
                defaultValue: "String arg 5: %@",
                comment: """
        single multiline comment 1 for value 5
        """
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
```

## Xcode autogeneration

The parser used by Xcode to build Swift sources automatically generates entries in the default
strings catalog when it encounters values of type `NSLocalizedString()`, `String(localized:)`
and `LocalizedStringResource` as well as some SwiftUI views that use `LocalizedStringKey`.

The expansion generated by this macro will be noticed by Xcode, and after a build,
Xcode will automatically create, modify, and delete entries into the appropriate string catalog
for you.

## Additional notes

Xcode will notice that a localization item it created has been changed to
manual management. If the localization disappears, it will **not** be auto-removed.
Instead, Xcode will mark the entry as `STALE`. If you see such an entry, you
can manually delete the localization if you want.

The beta versions of this product were versions 0.9.x. There were occasional source code
changes necessary when upgrading between those beta versions.

As of version 1.0.0, there will be no further source code changes between 1.x.y versions.
If a source code change is needed for a future release, the major version will be updated.
This allows sources that use this package to upgrade below the next major release and not
have to worry about source code modifications. The biggest change between 0.9.x releases
and 1.x.y releases is that the default separator has changed to a period (.) from the previous
underscore (-). If you wish to keep the old default separator, simply add the `separator: "-"`
paramater to the `LocalizedStrings` macro call. Any project that was including `separator: "."`
in the `LocalizedStrings` macro call may remove the parameter (or keep it, since it will still
work anyway). 

## Installing as a package

1. Within Xcode, go to your top-level project, and select the `Package Dependencies` tab.

2. If the `Localization` package is not present, add it using the URL
`https://github.com/Larry-Gensch/Localizing`

3. For `Dependency Rule`, select `Up to Next Major Version`. For the dependency, make sure
the value is `1.0.0 < 2.0.0`

4. Include it with all targets where you will be using the `@LocalizedStrings` macro.

5. It's usually best to clean and fully rebuild. If it asks you to `Enable and Trust` the package,
do so. (If you are security conscious, examine the source code to make sure it's doing what I'm
promising you it's doing...!)

## If Xcode autogeneration isn't working

If the `@LocalizedStrings` macro is unknown, make sure you included the package.
In addition, ensure that every source code file that uses the macro has the following import:

```swift
import Localizing
```

If you find that none, or perhaps only a few localizations are being
autogenerated into your string catalog, ensure you are looking for
the correct file (where localizations are stored are affected by
the `table` and `bundle` parameters passed to the macros), and that
the string catalog has been created and added to your project.

If that doesn't work, check your build settings for your target,
and filter using the word "local" to limit the settings on the
screen mostly to those involving localizations.

In the section `Localizations` in the build settings, ensure that the
following values are set to `Yes`:

- Localization Export Supported
- Localization Prefers String Catalogs
- Localized String SwiftUI Support
- Use Compiler to Extract Swift Strings

If you needed to change any of the above settings, simply rebuild and 
your localizations should start to export.

In the event that modifying the build settings doesn't work for you,
try removing (or stash) your string catalogs, re-create them, and try
again.

If you are having problems getting the comments to transfer to the
string catalog(s), edit the catalog as source code, and search for
any entries that say:

```json
      "extractionState" : "manual",
```

and change them to:

```json
      "extractionState" : "extracted_with_value",
```

This generally means that you overrode the comment sometime in the past. Xcode will prevent
any overridden comments from being regenerated if the `extractionState` is `manual`

## Still having problems?

Add an issue in the GitHub repository with as much information as you can, describing
what you've checked and have done to try to resolve issues yourself. I will make an
effort to update the documentation, fix any bugs, or add comments to the issue to help
with a resolution.
