//
//  ToggleWatchedUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol ToggleWatchedUseCase {
    func execute(for media: Media) async throws -> MediaWatchStatus
}

final class DefaultToggleWatchedUseCase: ToggleWatchedUseCase {
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository = DefaultWatchlistRepository()) {
        self.repository = repository
    }

    func execute(for media: Media) async throws -> MediaWatchStatus {
        let currentlyWatched = try await repository.isWatched(mediaId: media.id)

        if currentlyWatched {
            try await repository.unmarkAsWatched(mediaId: media.id)
            let isWatchlisted = try await repository.isWatchlisted(mediaId: media.id)
            return MediaWatchStatus(isWatchlisted: isWatchlisted, isWatched: false)
        } else {
            try await repository.markAsWatched(media)
            try await repository.removeFromWatchlist(mediaId: media.id)
            return MediaWatchStatus(isWatchlisted: false, isWatched: true)
        }
    }
}

