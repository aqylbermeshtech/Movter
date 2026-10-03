//
//  UpdateMenteeProfileRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public struct UpdateMenteeProfileRequestDTO: Codable {
    public let name: String?
    public let direction: String?
    public let category: String?
    public let directions: [String]?
    public let helpAreas: [String]?
    public let experience: String?

    public init(
        name: String? = nil,
        direction: String? = nil,
        category: String? = nil,
        directions: [String]? = nil,
        helpAreas: [String]? = nil,
        experience: String? = nil
    ) {
        self.name = name
        self.direction = direction
        self.category = category
        self.directions = directions
        self.helpAreas = helpAreas
        self.experience = experience
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case direction
        case category
        case directions
        case helpAreas = "help_areas"
        case experience
    }
}
