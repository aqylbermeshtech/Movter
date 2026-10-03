//
//  VerifyOTPUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

public final class VerifyOTPUseCase: VerifyOTPUseCaseProtocol {
    private let repository: OTPRepositoryProtocol
    
    public init(repository: OTPRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(method: OTPMethodDTO, contact: String, code: String) async throws -> OTPVerificationResultDTO {
        let verification = OTPVerificationDTO(method: method, contact: contact, code: code)
        return try await repository.verifyOTP(verification: verification)
    }
}

