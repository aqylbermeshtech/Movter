//
//  UpdateProfilePersonalResponseDTO.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public struct UpdateProfilePersonalResponseDTO: Codable {
    public let success: Bool
    public let message: String?
    public let error: String?
    public let data: UpdateProfilePersonalPayloadDTO?

    public init(
        success: Bool,
        message: String? = nil,
        error: String? = nil,
        data: UpdateProfilePersonalPayloadDTO? = nil
    ) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
    }
}

nonisolated public struct UpdateProfilePersonalPayloadDTO: Codable {
    public let profile: ProfileMeDataDTO
    public let emailVerificationRequired: Bool?
    public let maskedNewEmail: String?

    private enum CodingKeys: String, CodingKey {
        case profile
        case emailVerificationRequired = "email_verification_required"
        case maskedNewEmail = "masked_new_email"
    }
}
