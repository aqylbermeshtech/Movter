//
//  SocialAuthResponseDTO.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

public struct SocialAuthResponseDTO: Codable {
    public let success: Bool
    public let message: String?
    public let data: SocialAuthDataDTO?

    public init(success: Bool, message: String? = nil, data: SocialAuthDataDTO? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}
