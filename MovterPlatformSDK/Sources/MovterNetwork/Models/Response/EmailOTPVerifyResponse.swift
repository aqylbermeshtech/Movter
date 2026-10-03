//
//  EmailOTPVerifyResponse.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public struct EmailOTPVerifyResponse: Codable {
    public let success: Bool
    public let message: String?
    public let data: EmailOTPVerifyData?
    
    public init(success: Bool, message: String? = nil, data: EmailOTPVerifyData? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

nonisolated public struct EmailOTPVerifyData: Codable {
    public let userId: String
    public let status: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
    
    public init(
        userId: String,
        status: String,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String
    ) {
        self.userId = userId
        self.status = status
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

