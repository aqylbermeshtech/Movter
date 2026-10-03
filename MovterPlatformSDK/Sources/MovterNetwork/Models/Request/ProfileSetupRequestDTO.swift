//
//  ProfileSetupRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public struct ProfileSetupRequestDTO: Codable {
    public let name: String
    public let photoUrl: String?
    public let direction: String
    public let category: String?
    public let directions: [String]?
    public let skills: [String]
    public let experience: String
    public let about: String?
    public let menteeHelpAreas: [String]
    public let menteeWorkStatus: String
    public let mentorHelpAreas: [String]?
    public let mentorWorkStatus: String?

    public init(
        name: String,
        photoUrl: String? = nil,
        direction: String,
        category: String? = nil,
        directions: [String]? = nil,
        skills: [String],
        experience: String,
        about: String? = nil,
        menteeHelpAreas: [String],
        menteeWorkStatus: String,
        mentorHelpAreas: [String]? = nil,
        mentorWorkStatus: String? = nil
    ) {
        self.name = name
        self.photoUrl = photoUrl
        self.direction = direction
        self.category = category
        self.directions = directions
        self.skills = skills
        self.experience = experience
        self.about = about
        self.menteeHelpAreas = menteeHelpAreas
        self.menteeWorkStatus = menteeWorkStatus
        self.mentorHelpAreas = mentorHelpAreas
        self.mentorWorkStatus = mentorWorkStatus
    }

    enum CodingKeys: String, CodingKey {
        case name
        case photoUrl = "photo_url"
        case direction
        case category
        case directions
        case skills
        case experience
        case about
        case menteeHelpAreas = "mentee_help_areas"
        case menteeWorkStatus = "mentee_work_status"
        case mentorHelpAreas = "mentor_help_areas"
        case mentorWorkStatus = "mentor_work_status"
    }
}
