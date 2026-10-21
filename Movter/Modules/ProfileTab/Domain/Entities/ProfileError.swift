//
//  ProfileError.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

public enum ProfileError: LocalizedError, Equatable {
    case unauthenticated
    case userNotFound
    case updateFailed(String)
    case underlying(String)
    
    public var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "No active session found. Please log in again."
        case .userNotFound:
            return "User profile could not be found."
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        case .underlying(let message):
            return message
        }
    }
}
