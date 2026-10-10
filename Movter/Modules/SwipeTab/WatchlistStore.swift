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
protocol WatchlistStoring: AnyObject {
    // MARK: - Modern Async APIs
    /// Newest first.
    func fetchAll() async throws -> [WatchlistItem]
    /// Inserts, or replaces the existing entry for the same film.
    func save(_ item: WatchlistItem) async throws
    func delete(_ itemID: UUID) async throws

    // MARK: - Backward-Compatible Completion APIs
    func fetchAll(completion: @escaping (Result<[WatchlistItem], Error>) -> Void)
    func save(_ item: WatchlistItem, completion: @escaping (Result<Void, Error>) -> Void)
    func delete(_ itemID: UUID, completion: @escaping (Result<Void, Error>) -> Void)
}

/// The single place that picks the storage backend.
enum WatchlistStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore()
    }
}

/// Films the user has said they actually watched.
///
/// Deliberately not `SeenFilmsStoring`, which records every card the swipe deck dealt
/// including the rejections — that set answers "don't deal me this again", not "I have
/// seen this film", and only the second is worth counting or listing.
enum WatchedFilmsStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore(listName: "watched")
    }
}

/// Watchlist entries as a JSON file in Documents, dynamically resolving per active user account so
/// switching users can never expose the previous user's list or cause session staleness.
final class LocalWatchlistStore: WatchlistStoring {

    private let listName: String
    private let userIDProvider: () -> String?
    /// Serial: every operation rewrites the whole file.
    private let queue = DispatchQueue(label: "com.nurtore.movter.watchliststore")

    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let userID = userIDProvider() ?? "local"
        return documents.appendingPathComponent("\(listName)-\(userID).json")
    }

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

    /// - Parameter listName: which list this instance backs ("watchlist" or "watched").
    /// - Parameter userIDProvider: Evaluates active user ID dynamically (defaults to FirebaseAuth currentUser.uid).
    init(listName: String = "watchlist", userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.listName = listName
        self.userIDProvider = userIDProvider
    }

    convenience init(userID: String?, listName: String = "watchlist") {
        self.init(listName: listName, userIDProvider: { userID })
    }

    // MARK: - Modern Async APIs

    func fetchAll() async throws -> [WatchlistItem] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let items = try self.readFromDisk().sorted { $0.addedAt > $1.addedAt }
                    continuation.resume(returning: items)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(_ item: WatchlistItem) async throws {
        try await withCheckedThrowingContinuation { continuation in
            mutate(completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }) { items in
                if let index = items.firstIndex(where: { $0.tmdbID == item.tmdbID }) {
                    items[index] = item
                } else {
                    items.append(item)
                }
            }
        }
    }

    func delete(_ itemID: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            mutate(completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }) { items in
                items.removeAll { $0.id == itemID }
            }
        }
    }

    // MARK: - Completion-based APIs

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
        let targetURL = fileURL
        guard FileManager.default.fileExists(atPath: targetURL.path) else { return [] }
        let data = try Data(contentsOf: targetURL)
        guard !data.isEmpty else { return [] }
        return try decoder.decode([WatchlistItem].self, from: data)
    }

    private func writeToDisk(_ items: [WatchlistItem]) throws {
        let targetURL = fileURL
        let data = try encoder.encode(items)
        // Atomic: a crash mid-write leaves the previous file intact rather than a
        // truncated one that fails to decode.
        try data.write(to: targetURL, options: .atomic)
    }
}
