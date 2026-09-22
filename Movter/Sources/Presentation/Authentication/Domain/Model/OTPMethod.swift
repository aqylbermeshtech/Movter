//
//  OTPMethod.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation
//import MovterNetwork


enum OTPMethod: Equatable {
    case telegram
    case email
    
    func toDTO() -> OTPMethodDTO {
        switch self {
        case .telegram: return .telegram
        case .email: return .email
        }
    }
    
    static func from(dto: OTPMethodDTO) -> OTPMethod {
        switch dto {
        case .telegram: return .telegram
        case .email: return .email
        }
    }
}
