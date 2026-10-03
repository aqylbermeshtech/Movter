//
//  OTPRequest.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation

public enum OTPMethodDTO: Equatable {
    case telegram
    case email
}

public struct OTPVerificationDTO {
    public let method: OTPMethodDTO
    public let contact: String
    public let code: String
    
    public init(method: OTPMethodDTO, contact: String, code: String) {
        self.method = method
        self.contact = contact
        self.code = code
    }
}
