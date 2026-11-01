//
//  AuthError.swift
//  Movter
//

import Foundation

enum AuthError: LocalizedError, Equatable {
    case emptyFields
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case emailAlreadyInUse
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please fill in all fields."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters and include both letters and numbers."
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .networkError:
            return "Network connection error. Please try again."
        case .unknown(let message):
            return message
        }
    }
}

