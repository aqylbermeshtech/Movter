//
//  ProfileMeDTO.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation

public struct ProfileMeResponseDTO: Codable {
    public let success: Bool
    public let message: String?
    public let error: String?
    public let data: ProfileMeDataDTO?

    public init(success: Bool, message: String? = nil, error: String? = nil, data: ProfileMeDataDTO? = nil) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
    }
}

public struct ProfileMeDataDTO: Codable {
    public let userId: String?
    public let email: String?
    public let name: String?
    public let photoUrl: String?
    public let userType: String?
    public let about: String?
    public let isCompleted: Bool?
    public let isSettingsCompleted: Bool?
    public let completedAt: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let contacts: ProfileContactsDTO?

    public init(
        userId: String? = nil,
        email: String? = nil,
        name: String? = nil,
        photoUrl: String? = nil,
        userType: String? = nil,
        about: String? = nil,
        isCompleted: Bool? = nil,
        isSettingsCompleted: Bool? = nil,
        completedAt: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        contacts: ProfileContactsDTO? = nil
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.photoUrl = photoUrl
        self.userType = userType
        self.about = about
        self.isCompleted = isCompleted
        self.isSettingsCompleted = isSettingsCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contacts = contacts
    }

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case name
        case photoUrl = "photo_url"
        case userType = "user_type"
        case about
        case isCompleted = "is_completed"
        case isSettingsCompleted = "is_settings_completed"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contacts
    }
}

public struct ProfileContactsDTO: Codable {
    public let telegram: String?
    public let instagram: String?

    public init(telegram: String? = nil, instagram: String? = nil) {
        self.telegram = telegram
        self.instagram = instagram
    }

    private enum CodingKeys: String, CodingKey {
        case telegram
        case instagram
    }
}
