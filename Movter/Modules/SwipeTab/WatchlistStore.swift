//
//  WatchlistStore.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation
import FirebaseAuth

/// Where a list of saved films lives — the watchlist, and the films marked watched.
/// Both are the same shape (a film plus the date it was added to the list), so they
/// share this protocol and differ only in which file they read.
///
/// Completion-based even though the local store could answer synchronously: a remote
/// backend can't, and a synchronous protocol would force every call site to change the
/// day sync is added. Callbacks land on the main queue.
protocol WatchlistStoring: AnyObject {
    /// Newest first.
    func fetchAll(completion: @escaping @MainActor (Result<[WatchlistItem], Error>) -> Void)
    /// Inserts, or replaces the existing entry for the same film.
    func save(_ item: WatchlistItem, completion: @escaping @MainActor (Result<Void, Error>) -> Void)
    func delete(_ itemID: UUID, completion: @escaping @MainActor (Result<Void, Error>) -> Void)
}

/// The single place that picks the storage backend.
enum WatchlistStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore(userID: Auth.auth().currentUser?.uid)
    }
}

/// Films the user has said they actually watched.
///
/// Deliberately not `SeenFilmsStoring`, which records every card the swipe deck dealt
/// including the rejections — that set answers "don't deal me this again", not "I have
/// seen this film", and only the second is worth counting or listing.
enum WatchedFilmsStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore(userID: Auth.auth().currentUser?.uid, listName: "watched")
    }
}

/// Watchlist entries as a JSON file in Documents, one file per account so switching
/// users can't expose the previous user's list.
nonisolated final class LocalWatchlistStore: WatchlistStoring, Sendable {

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
    /// - Parameter listName: which list this instance backs, and so which file. Two
    ///   lists of the same shape rather than two near-identical store classes.
    init(userID: String?, listName: String = "watchlist") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("\(listName)-\(userID ?? "local").json")
    }

    // MARK: - WatchlistStoring

    func fetchAll(completion: @escaping @MainActor (Result<[WatchlistItem], Error>) -> Void) {
        queue.async {
            let result = Result { try self.readFromDisk() }
                .map { $0.sorted { $0.addedAt > $1.addedAt } }
            DispatchQueue.main.async { completion(result) }
        }
    }

    /// Dedupes by `tmdbID`, not `id` — re-liking a film already on the list updates
    /// its timestamp in place rather than adding a second entry.
    func save(_ item: WatchlistItem, completion: @escaping @MainActor (Result<Void, Error>) -> Void) {
        mutate(completion: completion) { items in
            if let index = items.firstIndex(where: { $0.tmdbID == item.tmdbID }) {
                items[index] = item
            } else {
                items.append(item)
            }
        }
    }

    func delete(_ itemID: UUID, completion: @escaping @MainActor (Result<Void, Error>) -> Void) {
        mutate(completion: completion) { items in
            items.removeAll { $0.id == itemID }
        }
    }

    // MARK: - Disk

    /// Read-modify-write on the serial queue so concurrent saves can't clobber
    /// each other.
    private func mutate(
        completion: @escaping @MainActor (Result<Void, Error>) -> Void,
        _ changes: @escaping @Sendable (inout [WatchlistItem]) -> Void
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
