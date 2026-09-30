//
//  AccessTokenJWTActiveRole.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation

nonisolated enum AccessTokenJWTActiveRole {

    static func persistedAppRoleRaw(from jwt: String) -> String? {
        let trimmedJWT = jwt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let payload = AccessTokenJWTPayload.dictionary(from: trimmedJWT),
              let raw = payload["active_role"] as? String else {
            return nil
        }

        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard value == "mentor" || value == "mentee" else { return nil }
        return value
    }
}
