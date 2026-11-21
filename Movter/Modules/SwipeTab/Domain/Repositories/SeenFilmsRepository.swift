//
//  SeenFilmsRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SeenFilmsRepository {
    func fetchSeenIDs() -> Set<Int>
    func fetchExcludedIDs(asOf now: Date) -> Set<Int>
    func fetchHistoryEntries() -> [Int: SwipeHistoryEntry]
    func markSeen(tmdbID: Int)
    func recordSwipe(tmdbID: Int, direction: SwipeDirection, at date: Date)
    func removeSwipeRecord(tmdbID: Int)
}

