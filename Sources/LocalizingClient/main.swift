//
//  main.swift
//  Localizing
//
//  Created by Larry Gensch on 2/14/24.
//  Copyright © 2024 by Larry Gensch. All rights reserved.
//

import Localizing
import Foundation

@LocalizedStrings(bundle: .main)
enum L {
    private enum Strings: String {
        case key1 = "Localized value 1"
        case key2 = "Localized value 2"
        case `import` = "Importing important stuff"
        case key4 = "Something with %@ and %lld"
        case accessibleFormat = "Card named %1$@ with color: %2$@"
        case nameWithColor = "%1$@ with color %2$@"
    }
}
