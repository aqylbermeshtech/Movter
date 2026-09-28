//
//  AccessTokenJWTPayload.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation

enum AccessTokenJWTPayload {

    static func dictionary(from jwt: String) -> [String: Any]? {
        let segments = jwt.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
