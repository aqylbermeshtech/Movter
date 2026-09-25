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
    public let direction: String?
    public let category: String?
    public let directions: [String]?
    public let experience: String?
    public let position: String?
    public let company: String?
    public let city: String?
    public let about: String?
    public let workStatus: String?
    public let skills: [String]?
    public let helpAreas: [String]?
    public let mentorHelp: [String]?
    public let mentorStatus: String?
    public let rating: Double?
    public let sessionCount: Int?
    public let isCompleted: Bool?
    public let isSettingsCompleted: Bool?
    public let completedAt: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let contacts: ProfileContactsDTO?
    public let packages: [ProfilePackageDTO]?

    public init(
        userId: String? = nil,
        email: String? = nil,
        name: String? = nil,
        photoUrl: String? = nil,
        userType: String? = nil,
        direction: String? = nil,
        category: String? = nil,
        directions: [String]? = nil,
        experience: String? = nil,
        position: String? = nil,
        company: String? = nil,
        city: String? = nil,
        about: String? = nil,
        workStatus: String? = nil,
        skills: [String]? = nil,
        helpAreas: [String]? = nil,
        mentorHelp: [String]? = nil,
        mentorStatus: String? = nil,
        rating: Double? = nil,
        sessionCount: Int? = nil,
        isCompleted: Bool? = nil,
        isSettingsCompleted: Bool? = nil,
        completedAt: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        contacts: ProfileContactsDTO? = nil,
        packages: [ProfilePackageDTO]? = nil
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.photoUrl = photoUrl
        self.userType = userType
        self.direction = direction
        self.category = category
        self.directions = directions
        self.experience = experience
        self.position = position
        self.company = company
        self.city = city
        self.about = about
        self.workStatus = workStatus
        self.skills = skills
        self.helpAreas = helpAreas
        self.mentorHelp = mentorHelp
        self.mentorStatus = mentorStatus
        self.rating = rating
        self.sessionCount = sessionCount
        self.isCompleted = isCompleted
        self.isSettingsCompleted = isSettingsCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contacts = contacts
        self.packages = packages
    }

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case name
        case photoUrl = "photo_url"
        case userType = "user_type"
        case direction
        case category
        case directions
        case experience
        case position
        case company
        case city
        case about
        case workStatus = "work_status"
        case skills
        case helpAreas = "help_areas"
        case mentorHelp = "mentor_help"
        case mentorStatus = "mentor_status"
        case rating
        case sessionCount = "session_count"
        case isCompleted = "is_completed"
        case isSettingsCompleted = "is_settings_completed"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contacts
        case packages
    }
}

public struct ProfileContactsDTO: Codable {
    public let telegram: String?
    public let linkedin: String?
    public let whatsapp: String?
    public let instagram: String?
    public let github: String?
    public let googleMeet: Bool?

    private enum CodingKeys: String, CodingKey {
        case telegram
        case linkedin
        case whatsapp
        case instagram
        case github
        case googleMeet = "google_meet"
    }
}

public struct ProfilePackageDTO: Codable {
    public let id: String?
    public let name: String?
    public let price: Double?
    public let currency: String?
    public let duration: Int?
    public let benefits: [String]?
    public let meetingFormat: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case currency
        case duration
        case benefits
        case meetingFormat = "meeting_format"
    }
}

