//
//  AuthMeResponseDTO.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public struct AuthMeResponseDTO: Codable {
    public let success: Bool
    public let message: String?
    public let error: String?
    public let data: AuthMeDataDTO?

    public init(
        success: Bool,
        message: String? = nil,
        error: String? = nil,
        data: AuthMeDataDTO? = nil
    ) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
    }
}

public struct AuthMeDataDTO: Codable {
    public let userId: String?
    public let activeRole: String?
    public let hasMenteeProfile: Bool?
    public let hasMentorProfile: Bool?

    public init(
        userId: String? = nil,
        activeRole: String? = nil,
        hasMenteeProfile: Bool? = nil,
        hasMentorProfile: Bool? = nil
    ) {
        self.userId = userId
        self.activeRole = activeRole
        self.hasMenteeProfile = hasMenteeProfile
        self.hasMentorProfile = hasMentorProfile
    }

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activeRole = "active_role"
        case hasMenteeProfile = "has_mentee_profile"
        case hasMentorProfile = "has_mentor_profile"
    }
}

