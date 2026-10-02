//
//  SocialAuthDataDTO.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public struct SocialAuthDataDTO: Codable {
    public let userId: String?
    public let status: String
    public let isNewUser: Bool?
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String?
    public let prefill: SocialAuthPrefillDTO?

    public init(
        userId: String? = nil,
        status: String,
        isNewUser: Bool? = nil,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String? = nil,
        prefill: SocialAuthPrefillDTO? = nil
    ) {
        self.userId = userId
        self.status = status
        self.isNewUser = isNewUser
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.prefill = prefill
    }

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case isNewUser = "is_new_user"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case prefill
    }
}

