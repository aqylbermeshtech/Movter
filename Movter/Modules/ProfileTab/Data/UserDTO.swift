//
//  UserDTO.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

struct UserDTO {
    let id: String
    let name: String
    let email: String
    let avatarURL: URL?

    func toDomain() -> UserProfile {
        UserProfile(
            id: id,
            name: name,
            email: email,
            avatarURL: avatarURL
        )
    }
}
