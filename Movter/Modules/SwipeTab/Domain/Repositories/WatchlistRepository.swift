//
//  WatchlistRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol WatchlistRepository {
    // MARK: - List Queries & Mutations
    func fetchAll(list: WatchlistPresentationType) async throws -> [WatchlistItem]
    func save(_ item: WatchlistItem, to list: WatchlistPresentationType) async throws
    func delete(id: UUID, from list: WatchlistPresentationType) async throws

    // MARK: - Media Status Checks & Shortcuts
    func isWatchlisted(mediaId: Int) async throws -> Bool
    func isWatched(mediaId: Int) async throws -> Bool
    func addToWatchlist(_ media: Media) async throws
    func removeFromWatchlist(mediaId: Int) async throws
    func markAsWatched(_ media: Media) async throws
    func unmarkAsWatched(mediaId: Int) async throws
}

