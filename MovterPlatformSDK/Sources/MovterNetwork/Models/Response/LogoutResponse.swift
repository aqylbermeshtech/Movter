//
//  LogoutResponse.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public struct LogoutResponse: Codable {
    public let success: Bool
    public let message: String?
    public let error: String?
    public let data: String?

    public init(success: Bool, message: String? = nil, error: String? = nil, data: String? = nil) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
    }
}
