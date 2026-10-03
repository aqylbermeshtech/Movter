//
//  AuthRepositoryImpl.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MentorNetwork
//import MentorStorage

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let dataSource: AuthenticationDataSourceProtocol

    public init(dataSource: AuthenticationDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func signIn(credentials: AuthCredentialsDTO) async throws -> Bool {
        switch credentials.method {
        case .email(let email):
            let response = try await dataSource.sendEmailOTP(email: email)
            return response.success
        case .phone(_, _):
            throw AuthError.phoneNotSupported
        }
    }

    public func logout() async throws -> Bool {
        let response = try await dataSource.logout()
        return response.success
    }

    public func deleteAccount() async throws -> DeleteAccountOutcome {
        let outcome = try await dataSource.deleteAccount()
        switch outcome {
        case .accountFullyRemoved:
            return outcome
        case let .retainedRemainingPersona(data):
            AccessTokenStore.shared.saveTokens(
                accessToken: data.accessToken,
                refreshToken: data.refreshToken,
                expiresIn: data.expiresIn
            )
            return outcome
        }
    }

    public func switchRole(toRole role: String) async throws -> SwitchRoleResultDTO {
        let response = try await dataSource.switchRole(role: role)

        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }

        AccessTokenStore.shared.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            expiresIn: data.expiresIn
        )

        return SwitchRoleResultDTO(activeRole: data.activeRole)
    }

    public func getAuthMe() async throws -> AuthMeDataDTO? {
        let response = try await dataSource.getAuthMe()
        guard response.success else { return nil }
        return response.data
    }

    public func signInWithGoogle(idToken: String) async throws -> SocialAuthResult {
        let response = try await dataSource.signInWithGoogle(idToken: idToken)
        return try mapSocialAuthResponse(response)
    }

    public func signInWithApple(idToken: String, name: String?) async throws -> SocialAuthResult {
        let response = try await dataSource.signInWithApple(idToken: idToken, name: name)
        return try mapSocialAuthResponse(response)
    }

    private func mapSocialAuthResponse(_ response: SocialAuthResponseDTO) throws -> SocialAuthResult {
        guard let data = response.data,
              !data.accessToken.isEmpty,
              !data.refreshToken.isEmpty else {
            throw NetworkError.decodingError
        }
        AccessTokenStore.shared.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            expiresIn: data.expiresIn
        )
        AccessTokenStore.shared.isProfileBootstrapPending = Self.isOnboardingRequired(data.status)
        let prefill: SocialAuthPrefill? = data.prefill.map {
            SocialAuthPrefill(name: $0.name, email: $0.email, photo: $0.photoUrl)
        }
        let status: SocialAuthResult.AuthStatus = Self.isOnboardingRequired(data.status)
            ? .onboardingRequired
            : .authenticated
        return SocialAuthResult(status: status, prefill: prefill)
    }

    private static func isOnboardingRequired(_ status: String) -> Bool {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "onboarding_required", "pending_onboarding", "pending", "new":
            return true
        default:
            return false
        }
    }
}

