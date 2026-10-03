//
//  OTPRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

public protocol OTPRepositoryProtocol {
    func verifyOTP(verification: OTPVerificationDTO) async throws -> OTPVerificationResultDTO
    func resendOTP(method: OTPMethodDTO, contact: String) async throws -> Bool
}
