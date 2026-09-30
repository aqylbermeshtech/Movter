//
//  AuthMethod.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import Foundation
//import MovterNetwork

enum AuthMethod {
    case phone(countryCode: String, number: String)
    case email(String)

    func toDTO() -> AuthMethodDTO {
        switch self {
        case .phone(let countryCode, let number):
            return .phone(countryCode: countryCode, number: number)
        case .email(let email):
            return .email(email)
        }
    }
}
