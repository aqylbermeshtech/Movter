//
//  ReviewError.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

enum ReviewError: LocalizedError, Equatable {
    case emptyFilmTitle
    case invalidScore(Int)
    case reviewTooLong(limit: Int)
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyFilmTitle:
            return "Please select a film or enter a title."
        case .invalidScore(let score):
            return "Score \(score) is invalid. Must be between 1 and 10."
        case .reviewTooLong(let limit):
            return "Review exceeds the limit of \(limit) characters."
        case .notFound:
            return "Review could not be found."
        }
    }
}
