//
//  RemoteAuthenticationDataSource.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MovterCore
//import MovterNetwork

nonisolated public final class RemoteAuthenticationDataSource: AuthenticationDataSourceProtocol {

    private let networkService: NetworkServiceProtocol
    private let router = Router<AuthEndPoint>()
    private let logger: LoggerProtocol

    public init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        self.logger = DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
    }
    
    public func sendEmailOTP(email: String) async throws -> EmailOTPSendResponse {
        logger.debug("Sending email OTP to: \(email)")
        
        let request = EmailOTPSendRequest(email: email)
        let endPoint = AuthEndPoint.sendEmailOTP(request: request)
        let urlRequest = try router.request(endPoint)
        
        let (data, response) = try await networkService.request(urlRequest)
        
        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)
        
        guard let result: EmailOTPSendResponse = try await context.process() else {
            throw NetworkError.decodingError
        }
        
        return result
    }
    
    public func verifyEmailOTP(email: String, code: String) async throws -> EmailOTPVerifyResponse {
        logger.debug("Verifying email OTP for: \(email)")
        
        let request = EmailOTPVerifyRequest(email: email, code: code)
        let endPoint = AuthEndPoint.verifyEmailOTP(request: request)
        let urlRequest = try router.request(endPoint)
        
        let (data, response) = try await networkService.request(urlRequest)
        
        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)
        
        guard let result: EmailOTPVerifyResponse = try await context.process() else {
            throw NetworkError.decodingError
        }
        
        return result
    }
    
    public func refreshToken(refreshToken: String) async throws -> RefreshTokenResponse {
        logger.debug("Refreshing token")
        
        let endPoint = AuthEndPoint.refreshToken(refreshToken: refreshToken)
        let urlRequest = try router.request(endPoint)
        
        let (data, response) = try await networkService.request(urlRequest)
        
        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)
        
        guard let result: RefreshTokenResponse = try await context.process() else {
            throw NetworkError.decodingError
        }
        
        return result
    }

    public func logout() async throws -> LogoutResponse {
        logger.debug("Logging out")

        let endPoint = AuthEndPoint.logout
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: LogoutResponse = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }

    public func getAuthMe() async throws -> AuthMeResponseDTO {
        logger.debug("HTTP GET auth/me")

        let endPoint = AuthEndPoint.authMe
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: AuthMeResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }

    public func deleteAccount() async throws -> DeleteAccountOutcome {
        logger.debug("Deleting account")

        let endPoint = AuthEndPoint.deleteAccount
        let urlRequest = try router.request(endPoint)
        let (data, response) = try await networkService.request(urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch http.statusCode {
        case 204:
            return .accountFullyRemoved
        case 200:
            let strategy = DefaultParseStrategy(data, response)
            let context = ParseContext(parseStrategy: strategy)

            guard let decoded: SwitchRoleResponse = try await context.process(),
                  decoded.success,
                  let payload = decoded.data else {
                throw NetworkError.decodingError
            }

            let normalizedRole = payload.activeRole
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard normalizedRole == "mentor" || normalizedRole == "mentee" else {
                throw NetworkError.decodingError
            }

            guard !payload.accessToken.isEmpty,
                  !payload.refreshToken.isEmpty,
                  payload.expiresIn > 0 else {
                throw NetworkError.decodingError
            }

            let tokens = SwitchRoleData(
                activeRole: normalizedRole,
                accessToken: payload.accessToken,
                refreshToken: payload.refreshToken,
                expiresIn: payload.expiresIn,
                tokenType: payload.tokenType
            )
            return .retainedRemainingPersona(tokens: tokens)
        default:
            throw NetworkError.serverError(http.statusCode)
        }
    }

    public func signInWithGoogle(idToken: String) async throws -> SocialAuthResponseDTO {
        logger.debug("Sign in with Google")

        let request = GoogleSignInRequestDTO(idToken: idToken)
        let endPoint = AuthEndPoint.googleSignIn(request: request)
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: SocialAuthResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }

    public func signInWithApple(idToken: String, name: String?) async throws -> SocialAuthResponseDTO {
        logger.debug("Sign in with Apple")

        let request = AppleSignInRequestDTO(idToken: idToken, name: name)
        let endPoint = AuthEndPoint.appleSignIn(request: request)
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: SocialAuthResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }

    public func switchRole(role: String) async throws -> SwitchRoleResponse {
        logger.debug("Switching role to: \(role)")

        let request = SwitchRoleRequest(role: role)
        let endPoint = AuthEndPoint.switchRole(request: request)
        let urlRequest = try router.request(endPoint)

        let (data, response) = try await networkService.request(urlRequest)

        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)

        guard let result: SwitchRoleResponse = try await context.process() else {
            throw NetworkError.decodingError
        }

        return result
    }
}

