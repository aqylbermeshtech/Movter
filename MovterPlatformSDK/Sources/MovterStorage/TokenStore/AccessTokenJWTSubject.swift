//
//  AccessTokenJWTSubject.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation

nonisolated enum AccessTokenJWTSubject {

    static func userId(from jwt: String) -> String? {
        guard let payload = AccessTokenJWTPayload.dictionary(from: jwt),
              let raw = payload["sub"] as? String else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
