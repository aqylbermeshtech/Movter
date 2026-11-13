//
//  ProfileError.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

public enum ProfileError: LocalizedError, Equatable {
    case unauthenticated
    case updateFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "No active session found. Please log in again."
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        }
    }
}
