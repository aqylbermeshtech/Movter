//
//  AuthRequest.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation

public struct AuthCredentialsDTO {
    public let method: AuthMethodDTO
    public let contact: String
    
    public init(method: AuthMethodDTO, contact: String) {
        self.method = method
        self.contact = contact
    }
}

public enum AuthMethodDTO {
    case phone(countryCode: String, number: String)
    case email(String)
}
