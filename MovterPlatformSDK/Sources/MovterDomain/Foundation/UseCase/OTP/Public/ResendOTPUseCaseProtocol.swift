//
//  ResendOTPUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation
//import MovterNetwork

public protocol ResendOTPUseCaseProtocol {
    func execute(method: OTPMethodDTO, contact: String) async throws -> Bool
}
