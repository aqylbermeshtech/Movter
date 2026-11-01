//
//  SwipeCardUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SwipeCardUseCase {
    func execute(media: Media, direction: SwipeDirection) async throws
}

final class DefaultSwipeCardUseCase: SwipeCardUseCase {

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
        seenFilmsRepository.markSeen(tmdbID: media.id)
        if direction == .like {
            let item = WatchlistItem(from: media)
            try await watchlistRepository.save(item, to: .watchlist)
        }
    }
}

