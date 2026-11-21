//
//  SwipeHistoryEntry.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

struct SwipeHistoryEntry: Codable, Equatable, Sendable {
    let tmdbID: Int
    var lastDirection: SwipeDirection
    var updatedAt: Date
    var passCount: Int
}
