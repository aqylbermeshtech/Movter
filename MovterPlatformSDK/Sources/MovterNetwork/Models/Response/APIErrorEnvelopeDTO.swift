//
//  APIErrorEnvelopeDTO.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

public struct APIErrorEnvelopeDTO: Decodable {
    public let success: Bool?
    public let message: String?
    public let error: APIErrorDetailsDTO?

    /// Backend sends either `error: {code, message}` or a bare string such as
    /// `"DATABASE_ERROR: failed to query categories"`, where the code is the prefix.
    public var errorCode: String? {
        if let code = error?.code?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty {
            return code
        }
        guard let raw = error?.message?.trimmingCharacters(in: .whitespacesAndNewlines),
              let separator = raw.firstIndex(of: ":")
        else { return nil }
        let prefix = String(raw[raw.startIndex..<separator])
        let isCodeLike = !prefix.isEmpty && prefix.allSatisfy { $0.isUppercase || $0 == "_" || $0.isNumber }
        return isCodeLike ? prefix : nil
    }

    public var errorFields: [String] {
        (error?.fields ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public var userFacingMessage: String? {
        let candidates = [message, error?.details, error?.message]
        for candidate in candidates {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}

