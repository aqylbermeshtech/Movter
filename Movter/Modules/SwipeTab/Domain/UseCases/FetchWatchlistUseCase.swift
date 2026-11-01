//
//  FetchWatchlistUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FetchWatchlistUseCase {
    func execute(list: WatchlistPresentationType) async throws -> [WatchlistItem]
}

final class DefaultFetchWatchlistUseCase: FetchWatchlistUseCase {

    private let repository: WatchlistRepository

    init(repository: WatchlistRepository = DefaultWatchlistRepository()) {
        self.repository = repository
    }

    func execute(list: WatchlistPresentationType) async throws -> [WatchlistItem] {
        try await repository.fetchAll(list: list)
    }
}

