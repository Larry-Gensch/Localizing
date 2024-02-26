# Localizing
@LocalizedStrings Macro

Use this macro to create localizable strings that are easily accessed within
your code base.

Simply prefix an enumeration with the `@LocalizedStrings` macro (that may be
called with an optional `prefix:` parameter). Within the enumeration, create
another enumeration called `Strings` (with a `RawValue` type `String`).
Each case in the `Strings enum` represents a keyName and the defaultValue
specified by the string value assigned to the case.

Limitation: Do not use simplified case without a value (the "=" is REQUIRED
to specify the string).

Once this is set up, the macro will generate constants within the outer enumeration.
These constants will map to a `NSLocalizedString` with the following values:

- term `constant name`: The keyName (case) found in the `Strings` enumeration
- term `defaultValue`: The (String) value found in the `Strings` enumeration
- term `tableName`: Defaults to `nil`, but can be overridden by defining a `static` String
constant named `defaultTableName` in the outer enumeration
- term `bundle`: Defaults to `.main`, but can be overridden by defining a `static` Bundle
constant named `defaultBundle` in the outer enumeration
- term `comment`: Always an empty string

The generated code will also extend the outer enumeration to conform to the
`LocalizedStrings` protocol, which provides the default values for `defaultTableName`
and `defaultBundle`

- Note: Example of macro use and output:

```swift
@LocalizedStrings(prefix: "main")
enum L {
    static let defaultTableName: String {
        "Special"
    }
    private enum Strings: String {
        case key1 = "localized key 1"
        case key2 = "localized key 2"
    }
}
```
This generates the following:
```swift
enum L {
    static let tableName = "Special"

    private enum Strings: String {
        case key1 = "localized value 1"
        case key2 = "localized value 2"
    }
    static let key1 = String(localized: "key1", defaultValue: "localized value 1", tableName: Self.defaultTableName, bundle: Self.bundle, comment: "key1 - localized value 1")
    static let key2 = String(localized: "key2", defaultValue: "localized value 2", tableName: Self.defaultTableName, bundle: Self.bundle, comment: "key2 - localized value 2")
}
extension L: LocalizedStrings {
}
```
