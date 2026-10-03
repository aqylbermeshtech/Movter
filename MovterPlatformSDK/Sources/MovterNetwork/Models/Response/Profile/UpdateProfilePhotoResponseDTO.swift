//
//  UpdateProfilePhotoResponseDTO.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

nonisolated public struct UpdateProfilePhotoResponseDTO: Codable {
    public let success: Bool
    public let message: String?
    public let error: String?
}
