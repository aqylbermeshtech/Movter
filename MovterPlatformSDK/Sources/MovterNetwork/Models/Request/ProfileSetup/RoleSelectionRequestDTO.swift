//
//  RoleSelectionRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public struct RoleSelectionRequestDTO: Codable {
    public let userType: String

    public init(userType: String) {
        self.userType = userType
    }

    enum CodingKeys: String, CodingKey {
        case userType = "user_type"
    }
}
