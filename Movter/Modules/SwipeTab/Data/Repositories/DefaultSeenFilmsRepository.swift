//
//  DefaultSeenFilmsRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultSeenFilmsRepository: SeenFilmsRepository {

    static let passCooldownInterval: TimeInterval = 14 * 86_400

    private let localDataSource: SeenFilmsLocalDataSource

    init(localDataSource: SeenFilmsLocalDataSource = UserDefaultsSeenFilmsDataSource()) {
        self.localDataSource = localDataSource
    }

    func fetchSeenIDs() -> Set<Int> {
        fetchExcludedIDs(asOf: Date())
    }

    func fetchExcludedIDs(asOf now: Date) -> Set<Int> {
        var excluded: Set<Int> = []
        for entry in fetchHistoryEntries().values where entry.tmdbID > 0 {
            switch entry.lastDirection {
            case .like:
                excluded.insert(entry.tmdbID)
            case .pass:
                if entry.passCount >= 2 {
                    excluded.insert(entry.tmdbID)
                } else if entry.passCount == 1,
                          now.timeIntervalSince(entry.updatedAt) < Self.passCooldownInterval {
                    excluded.insert(entry.tmdbID)
                }
            }
        }
        return excluded
    }

    func fetchHistoryEntries() -> [Int: SwipeHistoryEntry] {
        localDataSource.loadHistoryEntries()
    }

    func markSeen(tmdbID: Int) {
        recordSwipe(tmdbID: tmdbID, direction: .like, at: Date())
    }

    func recordSwipe(tmdbID: Int, direction: SwipeDirection, at date: Date) {
        guard tmdbID > 0 else { return }
        var entries = localDataSource.loadHistoryEntries()
        let existing = entries[tmdbID]

        switch direction {
        case .like:
            entries[tmdbID] = SwipeHistoryEntry(
                tmdbID: tmdbID,
                lastDirection: .like,
                updatedAt: date,
                passCount: existing?.passCount ?? 0
            )
        case .pass:
            entries[tmdbID] = SwipeHistoryEntry(
                tmdbID: tmdbID,
                lastDirection: .pass,
                updatedAt: date,
                passCount: (existing?.passCount ?? 0) + 1
            )
        }

        localDataSource.saveHistoryEntries(entries)
    }

    func removeSwipeRecord(tmdbID: Int) {
        var entries = localDataSource.loadHistoryEntries()
        guard entries.removeValue(forKey: tmdbID) != nil else { return }
        localDataSource.saveHistoryEntries(entries)
    }
}

