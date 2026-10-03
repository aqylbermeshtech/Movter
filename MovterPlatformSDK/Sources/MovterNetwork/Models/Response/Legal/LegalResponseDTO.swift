//
//  LegalResponseDTO.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public struct LegalResponseDTO: Codable {
    public let data: LegalDataDTO?
    public let error: String?
    public let message: String?
    public let success: Bool
    
    public init(data: LegalDataDTO? = nil, error: String? = nil, message: String? = nil, success: Bool = false) {
        self.data = data
        self.error = error
        self.message = message
        self.success = success
    }
}

nonisolated public struct LegalDataDTO: Codable {
    public let url: String
    public let version: String?
    
    public init(url: String, version: String? = nil) {
        self.url = url
        self.version = version
    }
}
