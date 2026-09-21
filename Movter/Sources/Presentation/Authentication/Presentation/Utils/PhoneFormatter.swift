//
//  PhoneFormatter.swift
//  Movter
//
//  Created by Nurtore on 21.09.2026.
//

import Foundation

struct PhoneFormatter {
    static func formatKazakhstanPhone(_ input: String) -> String {
        let limitedDigits = input.digits(max: 10)
        
        var formatted = ""
        for (index, character) in limitedDigits.enumerated() {
            if index == 3 || index == 6 || index == 8 {
                formatted.append(" ")
            }
            formatted.append(character)
        }
        
        return formatted
    }
    
    static func extractDigits(_ phone: String) -> String {
        return phone.digitsOnly
    }
    
    static func isValid(_ phone: String) -> Bool {
        let digits = extractDigits(phone)
        guard digits.count == 10 else { return false }
        guard let firstDigit = digits.first, firstDigit == "7" else { return false }
        return true
    }
}
