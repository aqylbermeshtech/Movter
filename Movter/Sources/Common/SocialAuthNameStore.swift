//
//  SocialAuthNameStore.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation

enum SocialAuthNameStore {
    private static let firstNameKey = "mentor.social_auth_prefill_first_name"
    private static let lastNameKey = "mentor.social_auth_prefill_last_name"

    static func save(fullName: String?) {
        let trimmed = fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return }

        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        UserDefaults.standard.set(parts.first ?? "", forKey: firstNameKey)
        UserDefaults.standard.set(parts.count > 1 ? parts[1] : "", forKey: lastNameKey)
    }

    static func consume() -> (firstName: String, lastName: String)? {
        let firstName = UserDefaults.standard.string(forKey: firstNameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !firstName.isEmpty else { return nil }

        let lastName = UserDefaults.standard.string(forKey: lastNameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        clear()
        return (firstName, lastName)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: firstNameKey)
        UserDefaults.standard.removeObject(forKey: lastNameKey)
    }
}

