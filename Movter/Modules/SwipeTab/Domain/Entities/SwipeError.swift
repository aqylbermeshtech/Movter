//
//  SwipeError.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

enum SwipeError: LocalizedError, Equatable {
    case offline
    case sessionLimitReached
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .offline:
            return "You're offline. Please check your connection."
        case .sessionLimitReached:
            return "Session limit reached."
        case .itemNotFound:
            return "Item could not be found."
        }
    }
}

