//
//  UpdateProfilePhotoRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public struct UpdateProfilePhotoRequestDTO: Codable {
    public let photoUrl: String

    public init(photoUrl: String) {
        self.photoUrl = photoUrl
    }

    private enum CodingKeys: String, CodingKey {
        case photoUrl = "photo_url"
    }
}
