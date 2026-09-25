//
//  VerifyOTPUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation
//import MovterNetwork

public protocol VerifyOTPUseCaseProtocol {
    func execute(method: OTPMethodDTO, contact: String, code: String) async throws -> OTPVerificationResultDTO
}
