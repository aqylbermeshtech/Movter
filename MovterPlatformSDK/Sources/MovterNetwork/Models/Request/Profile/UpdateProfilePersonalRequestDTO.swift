//
//  UpdateProfilePersonalRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public struct UpdateProfilePersonalRequestDTO: Codable {
    public let name: String?
    public let email: String?

    public init(name: String? = nil, email: String? = nil) {
        self.name = name
        self.email = email
    }
}

