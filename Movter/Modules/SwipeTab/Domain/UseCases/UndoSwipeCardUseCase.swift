//
//  UndoSwipeCardUseCase.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

protocol UndoSwipeCardUseCase {
    func execute(media: Media, direction: SwipeDirection) async throws
}

final class DefaultUndoSwipeCardUseCase: UndoSwipeCardUseCase {
    private let seenFilmsRepository: SeenFilmsRepository
    private let watchlistRepository: WatchlistRepository

    init(
        seenFilmsRepository: SeenFilmsRepository = DefaultSeenFilmsRepository(),
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository()
    ) {
        self.seenFilmsRepository = seenFilmsRepository
        self.watchlistRepository = watchlistRepository
    }

    func execute(media: Media, direction: SwipeDirection) async throws {
        seenFilmsRepository.removeSwipeRecord(tmdbID: media.id)
        if direction == .like {
            try await watchlistRepository.removeFromWatchlist(mediaId: media.id)
        }
    }
}
