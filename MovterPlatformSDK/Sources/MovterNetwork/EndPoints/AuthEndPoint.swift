//
//  AuthEndPoint.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public enum AuthEndPoint {
    // Email OTP
    case sendEmailOTP(request: EmailOTPSendRequest)
    case verifyEmailOTP(request: EmailOTPVerifyRequest)
    
    // Token management
    case refreshToken(refreshToken: String)
    case logout
    case deleteAccount

    case authMe

    // Social auth
    case googleSignIn(request: GoogleSignInRequestDTO)
    case appleSignIn(request: AppleSignInRequestDTO)

    // Role
    case switchRole(request: SwitchRoleRequest)
}

extension AuthEndPoint: EndPointType {
    
    public var baseURL: URL {
        return NetworkConfiguration.shared.baseURL
    }
    
    public var path: String {
        switch self {
        case .sendEmailOTP:
            return "/v1/auth/email-otp/send"
        case .verifyEmailOTP:
            return "/v1/auth/email-otp/verify"
        case .refreshToken:
            return "/v1/auth/token/refresh"
        case .logout:
            return "/v1/auth/logout"
        case .deleteAccount:
            return "v1/account"
        case .authMe:
            return "/v1/auth/me"
        case .googleSignIn:
            return "/v1/auth/google"
        case .appleSignIn:
            return "/v1/auth/apple"
        case .switchRole:
            return "/v1/auth/switch-role"
        }
    }

    public var httpMethod: RequestMethod {
        switch self {
        case .sendEmailOTP, .verifyEmailOTP, .refreshToken, .logout, .switchRole, .googleSignIn, .appleSignIn:
            return .post
        case .authMe:
            return .get
        case .deleteAccount:
            return .delete
        }
    }
    
    public var task: RequestTask {
        switch self {
        case let .sendEmailOTP(request):
            return .requestEncodable(requestModel: request)
            
        case let .verifyEmailOTP(request):
            return .requestEncodable(requestModel: request)
            
        case let .refreshToken(refreshToken):
            return .requestParameters(
                bodyParameters: ["refresh_token": refreshToken],
                bodyEncoding: .jsonEncoding,
                urlParameters: nil
            )
        case .logout:
            return .request
        case .authMe:
            return .request
        case .deleteAccount:
            return .request
        case let .googleSignIn(request):
            return .requestEncodable(requestModel: request)
        case let .appleSignIn(request):
            return .requestEncodable(requestModel: request)
        case let .switchRole(request):
            return .requestEncodable(requestModel: request)
        }
    }
    
    public var headers: RequestHeaders? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}

