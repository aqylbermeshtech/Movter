//
//  SwitchRoleData.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public struct SwitchRoleResponse: Codable {
    public let success: Bool
    public let message: String?
    public let data: SwitchRoleData?

    public init(success: Bool, message: String? = nil, data: SwitchRoleData? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

nonisolated public struct SwitchRoleData: Codable {
    public let activeRole: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String

    public init(
        activeRole: String,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String
    ) {
        self.activeRole = activeRole
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }

    private enum CodingKeys: String, CodingKey {
        case activeRole = "active_role"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

