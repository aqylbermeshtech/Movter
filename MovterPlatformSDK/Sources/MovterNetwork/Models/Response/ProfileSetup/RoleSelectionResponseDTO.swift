//
//  RoleSelectionResponseDTO.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public struct RoleSelectionResponseDTO: Codable {
    public let success: Bool
    public let message: String?
    public let data: RoleSelectionDataDTO?

    public init(success: Bool, message: String?, data: RoleSelectionDataDTO?) {
        self.success = success
        self.message = message
        self.data = data
    }
}

public struct RoleSelectionDataDTO: Codable {
    public let message: String?
    public let userType: String

    enum CodingKeys: String, CodingKey {
        case message
        case userType = "user_type"
    }
}
