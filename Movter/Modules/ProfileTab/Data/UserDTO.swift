//
//  UserDTO.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

struct UserDTO: Decodable {
    let id: String
    let name: String
    let email: String
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatarURL = "avatar_url"
    }

    func toDomain() -> UserProfile {
        UserProfile(
            id: id,
            name: name,
            email: email,
            avatarURL: avatarURL
        )
    }
}
