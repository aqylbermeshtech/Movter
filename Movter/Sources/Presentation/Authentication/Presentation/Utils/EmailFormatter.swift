//
//  EmailFormatter.swift
//  Movter
//
//  Created by Nurtore on 21.09.2026.
//

import Foundation

struct EmailFormatter {
    static func normalize(_ email: String) -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let withoutSpaces = lowercased.replacingOccurrences(of: " ", with: "")
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789@._%+-")
        let filtered = withoutSpaces.unicodeScalars.filter { allowedCharacters.contains($0) }
        
        return String(String.UnicodeScalarView(filtered))
    }
    
    static func isValid(_ email: String) -> Bool {
        let normalizedEmail = normalize(email)
        guard !normalizedEmail.isEmpty else { return false }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailPredicate.evaluate(with: normalizedEmail)
    }
}
