//
//  OTPRepositoryImpl.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorStorage
//import MentorNetwork

public final class OTPRepositoryImpl: OTPRepositoryProtocol {
    private let dataSource: AuthenticationDataSourceProtocol

    public init(dataSource: AuthenticationDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func verifyOTP(verification: OTPVerificationDTO) async throws -> OTPVerificationResultDTO {
        switch verification.method {
        case .email:
            let response = try await dataSource.verifyEmailOTP(
                email: verification.contact,
                code: verification.code
            )

            if response.success, let data = response.data {
                AccessTokenStore.shared.saveTokens(
                    accessToken: data.accessToken,
                    refreshToken: data.refreshToken,
                    expiresIn: data.expiresIn
                )
                AccessTokenStore.shared.isProfileBootstrapPending = (data.status == "pending_onboarding")
            }

            return OTPVerificationResultDTO(
                isSuccess: response.success,
                errorMessage: response.message,
                status: response.data?.status,
                userId: response.data?.userId
            )

        case .telegram:
            return OTPVerificationResultDTO(isSuccess: false, errorMessage: "Telegram OTP не поддерживается")
        }
    }
    
    public func resendOTP(method: OTPMethodDTO, contact: String) async throws -> Bool {
        switch method {
        case .email:
            let response = try await dataSource.sendEmailOTP(email: contact)
            return response.success
        case .telegram:
            return false
        }
    }
}

