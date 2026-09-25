//
//  OTPVerificationResult.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation
//import MovterNetwork

struct OTPVerificationResult {
    let isSuccess: Bool
    let errorMessage: String?
    let status: String?
    let userId: String?
    
    init(isSuccess: Bool, errorMessage: String?, status: String?, userId: String?) {
        self.isSuccess = isSuccess
        self.errorMessage = errorMessage
        self.status = status
        self.userId = userId
    }
    
    init(dto: OTPVerificationResultDTO) {
        self.isSuccess = dto.isSuccess
        self.errorMessage = dto.errorMessage
        self.status = dto.status
        self.userId = dto.userId
    }
    
    var isCompletedOnboarding: Bool {
        status == "completed_onboarding"
    }

    var isPendingOnboarding: Bool {
        status == "pending_onboarding"
    }
}
