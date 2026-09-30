//
//  RefreshTokenResponse.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

public nonisolated struct RefreshTokenResponse: Codable, Sendable {
    public let success: Bool
    public let message: String?
    public let data: RefreshTokenData?
    
    public init(success: Bool, message: String? = nil, data: RefreshTokenData? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

nonisolated public struct RefreshTokenData: Codable, Sendable {
    public let accessToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let refreshToken: String
    
    public init(accessToken: String, expiresIn: Int, tokenType: String, refreshToken: String) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.refreshToken = refreshToken
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
    }
}
