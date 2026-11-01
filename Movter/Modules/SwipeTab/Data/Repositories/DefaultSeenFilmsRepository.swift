//
//  DefaultSeenFilmsRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultSeenFilmsRepository: SeenFilmsRepository {

    private let localDataSource: SeenFilmsLocalDataSource

    init(localDataSource: SeenFilmsLocalDataSource = UserDefaultsSeenFilmsDataSource()) {
        self.localDataSource = localDataSource
    }

    func fetchSeenIDs() -> Set<Int> {
        localDataSource.loadSeenIDs()
    }

    func markSeen(tmdbID: Int) {
        var ids = localDataSource.loadSeenIDs()
        guard ids.insert(tmdbID).inserted else { return }
        localDataSource.saveSeenIDs(ids)
    }
}

