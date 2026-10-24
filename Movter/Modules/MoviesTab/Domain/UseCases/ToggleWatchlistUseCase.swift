//
//  ToggleWatchlistUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol ToggleWatchlistUseCase {
    func execute(for media: Media) async throws -> Bool
}

final class DefaultToggleWatchlistUseCase: ToggleWatchlistUseCase {
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository) {
        self.repository = repository
    }

    func execute(for media: Media) async throws -> Bool {
        let currentlyInWatchlist = try await repository.isWatchlisted(mediaId: media.id)
        
        if currentlyInWatchlist {
            try await repository.removeFromWatchlist(mediaId: media.id)
            return false
        } else {
            try await repository.addToWatchlist(media)
            return true
        }
    }
}

