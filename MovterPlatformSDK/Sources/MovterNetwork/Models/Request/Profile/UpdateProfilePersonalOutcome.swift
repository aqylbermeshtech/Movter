//
//  UpdateProfilePersonalOutcome.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public struct UpdateProfilePersonalOutcome {
    public let profile: ProfileMeDataDTO
    public let maskedNewEmail: String?
    public let emailVerificationRequired: Bool?

    public init(profile: ProfileMeDataDTO, maskedNewEmail: String?, emailVerificationRequired: Bool?) {
        self.profile = profile
        self.maskedNewEmail = maskedNewEmail
        self.emailVerificationRequired = emailVerificationRequired
    }
}

