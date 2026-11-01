//
//  GetMediaWatchStatusUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetMediaWatchStatusUseCase {
    func execute(mediaId: Int) async throws -> MediaWatchStatus
}

final class DefaultGetMediaWatchStatusUseCase: GetMediaWatchStatusUseCase {
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository = DefaultWatchlistRepository()) {
        self.repository = repository
    }

    func execute(mediaId: Int) async throws -> MediaWatchStatus {
        async let watchlisted = repository.isWatchlisted(mediaId: mediaId)
        async let watched = repository.isWatched(mediaId: mediaId)

        return try await MediaWatchStatus(
            isWatchlisted: watchlisted,
            isWatched: watched
        )
    }
}

