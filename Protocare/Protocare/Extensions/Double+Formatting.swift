//
//  Double+Formatting.swift
//  Protocare
//
//  Double formatting extensions
//

import Foundation

extension Double {
    func roundedString(maxFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
