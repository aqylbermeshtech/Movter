//
//  AuthEndPoint.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public enum AuthEndPoint {
    case sendEmailOTP(request: EmailOTPSendRequest)
    case verifyEmailOTP(request: EmailOTPVerifyRequest)
    case refreshToken(refreshToken: String)
    case logout
    case authMe
    case deleteAccount
    case googleSignIn(request: GoogleSignInRequestDTO)
    case appleSignIn(request: AppleSignInRequestDTO)
    case switchRole(request: SwitchRoleRequest)
}

extension AuthEndPoint: EndPointType {

    public var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    public var path: String {
        switch self {
        case .sendEmailOTP:
            return "v1/auth/email/otp/send"
        case .verifyEmailOTP:
            return "v1/auth/email/otp/verify"
        case .refreshToken:
            return "v1/auth/token/refresh"
        case .logout:
            return "v1/auth/logout"
        case .authMe:
            return "v1/auth/me"
        case .deleteAccount:
            return "v1/auth/account"
        case .googleSignIn:
            return "v1/auth/social/google"
        case .appleSignIn:
            return "v1/auth/social/apple"
        case .switchRole:
            return "v1/auth/role/switch"
        }
    }

    public var httpMethod: RequestMethod {
        switch self {
        case .sendEmailOTP, .verifyEmailOTP, .refreshToken, .googleSignIn, .appleSignIn, .switchRole:
            return .post
        case .logout:
            return .post
        case .authMe:
            return .get
        case .deleteAccount:
            return .delete
        }
    }

    public var task: RequestTask {
        switch self {
        case .sendEmailOTP(let request):
            return .requestEncodable(requestModel: request)
        case .verifyEmailOTP(let request):
            return .requestEncodable(requestModel: request)
        case .refreshToken(let refreshToken):
            return .requestEncodable(requestModel: RefreshTokenRequestBody(refreshToken: refreshToken))
        case .googleSignIn(let request):
            return .requestEncodable(requestModel: request)
        case .appleSignIn(let request):
            return .requestEncodable(requestModel: request)
        case .switchRole(let request):
            return .requestEncodable(requestModel: request)
        case .logout, .authMe, .deleteAccount:
            return .request
        }
    }

    public var headers: RequestHeaders? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}

// MARK: - Helper

nonisolated private struct RefreshTokenRequestBody: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
