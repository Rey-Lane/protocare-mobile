//
//  String+Validation.swift
//  Protocare
//
//  String validation extensions
//

import Foundation

extension String {
    var isValidEmail: Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}
