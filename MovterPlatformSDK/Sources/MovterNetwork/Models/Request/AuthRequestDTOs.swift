//
//  AuthRequestDTOs.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

// MARK: - Email OTP

public struct EmailOTPSendRequest: Encodable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}

public struct EmailOTPVerifyRequest: Encodable {
    public let email: String
    public let code: String

    public init(email: String, code: String) {
        self.email = email
        self.code = code
    }
}

// MARK: - Social Auth

public struct GoogleSignInRequestDTO: Encodable {
    public let idToken: String

    public init(idToken: String) {
        self.idToken = idToken
    }

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}

public struct AppleSignInRequestDTO: Encodable {
    public let idToken: String
    public let name: String?

    public init(idToken: String, name: String?) {
        self.idToken = idToken
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case name
    }
}

// MARK: - Role Switch

public struct SwitchRoleRequest: Encodable {
    public let role: String

    public init(role: String) {
        self.role = role
    }
}
