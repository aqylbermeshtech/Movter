//
//  OTPVerificationResultDTO.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation

public struct OTPVerificationResultDTO {
    public let isSuccess: Bool
    public let errorMessage: String?
    public let status: String?
    public let userId: String?

    public init(isSuccess: Bool, errorMessage: String? = nil, status: String? = nil, userId: String? = nil) {
        self.isSuccess = isSuccess
        self.errorMessage = errorMessage
        self.status = status
        self.userId = userId
    }
}
