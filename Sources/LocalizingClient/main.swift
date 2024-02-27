import Localizing
import Foundation

@LocalizedStrings(bundle: .main)
enum L {
    private enum Strings: String {
        case key1 = "Localized value 1"
        case key2 = "Localized value 2"
        case `import` = "Importing important shit"
    }
}
