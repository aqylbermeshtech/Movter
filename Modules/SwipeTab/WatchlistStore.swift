//
//  WatchlistStore.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation
import FirebaseAuth

/// Where a user's watchlist lives.
///
/// Completion-based even though the local store could answer synchronously: a remote
/// backend can't, and a synchronous protocol would force every call site to change the
/// day sync is added. Callbacks land on the main queue.
protocol WatchlistStoring: AnyObject {
    /// Newest first.
    func fetchAll(completion: @escaping (Result<[WatchlistItem], Error>) -> Void)
    /// Inserts, or replaces the existing entry for the same film.
    func save(_ item: WatchlistItem, completion: @escaping (Result<Void, Error>) -> Void)
    func delete(_ itemID: UUID, completion: @escaping (Result<Void, Error>) -> Void)
}

/// The single place that picks the storage backend.
enum WatchlistStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore(userID: Auth.auth().currentUser?.uid)
    }
}

/// Watchlist entries as a JSON file in Documents, one file per account so switching
/// users can't expose the previous user's list.
final class LocalWatchlistStore: WatchlistStoring {

    private let fileURL: URL
    /// Serial: every operation rewrites the whole file.
    private let queue = DispatchQueue(label: "com.nurtore.movter.watchliststore")

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// - Parameter userID: Firebase uid; nil falls back to a shared local file.
    init(userID: String?) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("watchlist-\(userID ?? "local").json")
    }

    // MARK: - WatchlistStoring

    func fetchAll(completion: @escaping (Result<[WatchlistItem], Error>) -> Void) {
        queue.async {
            let result = Result { try self.readFromDisk() }
                .map { $0.sorted { $0.addedAt > $1.addedAt } }
            DispatchQueue.main.async { completion(result) }
        }
    }

    /// Dedupes by `tmdbID`, not `id` — re-liking a film already on the list updates
    /// its timestamp in place rather than adding a second entry.
    func save(_ item: WatchlistItem, completion: @escaping (Result<Void, Error>) -> Void) {
        mutate(completion: completion) { items in
            if let index = items.firstIndex(where: { $0.tmdbID == item.tmdbID }) {
                items[index] = item
            } else {
                items.append(item)
            }
        }
    }

    func delete(_ itemID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        mutate(completion: completion) { items in
            items.removeAll { $0.id == itemID }
        }
    }

    // MARK: - Disk

    /// Read-modify-write on the serial queue so concurrent saves can't clobber
    /// each other.
    private func mutate(
        completion: @escaping (Result<Void, Error>) -> Void,
        _ changes: @escaping (inout [WatchlistItem]) -> Void
    ) {
        queue.async {
            let result = Result {
                var items = try self.readFromDisk()
                changes(&items)
                try self.writeToDisk(items)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func readFromDisk() throws -> [WatchlistItem] {
        // Missing file is the first-launch state, not a failure.
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }
        return try decoder.decode([WatchlistItem].self, from: data)
    }

    private func writeToDisk(_ items: [WatchlistItem]) throws {
        let data = try encoder.encode(items)
        // Atomic: a crash mid-write leaves the previous file intact rather than a
        // truncated one that fails to decode.
        try data.write(to: fileURL, options: .atomic)
    }
}
