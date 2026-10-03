//
//  ResendOTPUseCase.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

public final class ResendOTPUseCase: ResendOTPUseCaseProtocol {
    private let repository: OTPRepositoryProtocol
    
    public init(repository: OTPRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(method: OTPMethodDTO, contact: String) async throws -> Bool {
        return try await repository.resendOTP(method: method, contact: contact)
    }
}
