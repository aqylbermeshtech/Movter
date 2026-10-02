//
//  AuthenticationDataSourceProtocol.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MovterNetwork

public protocol AuthenticationDataSourceProtocol {
    func sendEmailOTP(email: String) async throws -> EmailOTPSendResponse
    func verifyEmailOTP(email: String, code: String) async throws -> EmailOTPVerifyResponse
    func refreshToken(refreshToken: String) async throws -> RefreshTokenResponse
    func logout() async throws -> LogoutResponse
    func getAuthMe() async throws -> AuthMeResponseDTO
    func deleteAccount() async throws -> DeleteAccountOutcome
    func switchRole(role: String) async throws -> SwitchRoleResponse
    func signInWithGoogle(idToken: String) async throws -> SocialAuthResponseDTO
    func signInWithApple(idToken: String, name: String?) async throws -> SocialAuthResponseDTO
}
