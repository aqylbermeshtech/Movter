//
//  SeenFilmsRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SeenFilmsRepository {
    func fetchSeenIDs() -> Set<Int>
    func markSeen(tmdbID: Int)
}

