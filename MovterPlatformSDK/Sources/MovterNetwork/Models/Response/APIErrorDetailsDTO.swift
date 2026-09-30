//
//  APIErrorDetailsDTO.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

nonisolated public struct APIErrorDetailsDTO: Decodable, Sendable {
    public let code: String?
    public let message: String?
    public let details: String?
    /// Sections the backend refused to publish without, such as `packages` or `calendar`.
    public let fields: [String]?

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let text = try? single.decode(String.self) {
            self.code = nil
            self.message = text
            self.details = nil
            self.fields = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try? container.decodeIfPresent(String.self, forKey: .code)
        self.message = try? container.decodeIfPresent(String.self, forKey: .message)
        self.details = try? container.decodeIfPresent(String.self, forKey: .details)
        self.fields = try? container.decodeIfPresent([String].self, forKey: .fields)
    }

    private enum CodingKeys: String, CodingKey {
        case code, message, details, fields
    }
}

