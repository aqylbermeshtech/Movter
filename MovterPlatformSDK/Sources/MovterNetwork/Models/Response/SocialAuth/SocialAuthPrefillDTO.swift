//
//  SocialAuthPrefillDTO.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public struct SocialAuthPrefillDTO: Codable {
    public let name: String?
    public let email: String?
    public let photoUrl: String?

    public init(name: String? = nil, email: String? = nil, photoUrl: String? = nil) {
        self.name = name
        self.email = email
        self.photoUrl = photoUrl
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case email
        case photoUrl = "photo_url"
    }
}

