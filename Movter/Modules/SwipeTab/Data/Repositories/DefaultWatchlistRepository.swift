//
//  DefaultWatchlistRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultWatchlistRepository: WatchlistRepository {

    private let localDataSource: WatchlistLocalDataSource
    private let queue = DispatchQueue(label: "com.nurtore.movter.watchlist.repository")

    init(localDataSource: WatchlistLocalDataSource = LocalFileWatchlistDataSource()) {
        self.localDataSource = localDataSource
    }

    // MARK: - List Queries & Mutations

    func fetchAll(list: WatchlistPresentationType) async throws -> [WatchlistItem] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let items = try self.localDataSource.loadItems(listName: list.storageName).sorted { $0.addedAt > $1.addedAt }
                    continuation.resume(returning: items)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(_ item: WatchlistItem, to list: WatchlistPresentationType) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    var items = try self.localDataSource.loadItems(listName: list.storageName)
                    if let index = items.firstIndex(where: { $0.tmdbID == item.tmdbID }) {
                        items[index] = item
                    } else {
                        items.append(item)
                    }
                    try self.localDataSource.saveItems(items, listName: list.storageName)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func delete(id: UUID, from list: WatchlistPresentationType) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    var items = try self.localDataSource.loadItems(listName: list.storageName)
                    items.removeAll { $0.id == id }
                    try self.localDataSource.saveItems(items, listName: list.storageName)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Media Status Checks & Shortcuts

    func isWatchlisted(mediaId: Int) async throws -> Bool {
        let items = try await fetchAll(list: .watchlist)
        return items.contains { $0.tmdbID == mediaId }
    }

    func isWatched(mediaId: Int) async throws -> Bool {
        let items = try await fetchAll(list: .watched)
        return items.contains { $0.tmdbID == mediaId }
    }

    func addToWatchlist(_ media: Media) async throws {
        let item = WatchlistItem(from: media)
        try await save(item, to: .watchlist)
    }

    func removeFromWatchlist(mediaId: Int) async throws {
        let items = try await fetchAll(list: .watchlist)
        if let target = items.first(where: { $0.tmdbID == mediaId }) {
            try await delete(id: target.id, from: .watchlist)
        }
    }

    func markAsWatched(_ media: Media) async throws {
        let item = WatchlistItem(from: media)
        try await save(item, to: .watched)
    }

    func unmarkAsWatched(mediaId: Int) async throws {
        let items = try await fetchAll(list: .watched)
        if let target = items.first(where: { $0.tmdbID == mediaId }) {
            try await delete(id: target.id, from: .watched)
        }
    }
}

