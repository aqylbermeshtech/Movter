//
//  WatchListRepository.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol WatchlistRepository {
    func isWatchlisted(mediaId: Int) async throws -> Bool
    func isWatched(mediaId: Int) async throws -> Bool
    func addToWatchlist(_ media: Media) async throws
    func removeFromWatchlist(mediaId: Int) async throws
    func markAsWatched(_ media: Media) async throws
    func unmarkAsWatched(mediaId: Int) async throws
}
