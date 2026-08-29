//
//  RecentSearchesStore.swift
//  Movter
//
//  Created by Nurtore on 27.08.2026.
//

import Foundation

/// The handful of most recent film queries, newest first.
///
/// Deliberately not completion-based like `ReviewStoring` and `WatchlistStoring`:
/// `UserDefaults` answers synchronously and a write here has no failure worth
/// reporting. It is a protocol so the search overlay can be exercised against a
/// scratch store instead of the real one.
protocol RecentSearchesStoring: AnyObject {
    /// Newest first.
    func all() -> [String]
    /// Moves an existing term back to the top rather than duplicating it, and trims the
    /// list to the store's limit.
    func add(_ term: String)
    func remove(_ term: String)
    func clear()
}

/// The single place that picks the storage backend.
enum RecentSearchesStoreFactory {
    /// Not scoped per account, unlike the review and watchlist stores: a shared device
    /// shows the same recents to everyone signed in on it. Scoping it is a change to
    /// this one line — pass the Firebase uid through as a key suffix.
    static func makeStore() -> RecentSearchesStoring {
        LocalRecentSearchesStore()
    }
}

/// Recents as a plain string array in `UserDefaults`, small enough that a JSON file
/// (like the review and watchlist stores use) would be overkill.
final class LocalRecentSearchesStore: RecentSearchesStoring {

    private let defaults: UserDefaults
    private let key: String
    private let limit: Int

    init(defaults: UserDefaults = .standard, key: String = "recent_searches", limit: Int = 8) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
    }

    func all() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func add(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var items = all().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        items.insert(trimmed, at: 0)
        defaults.set(Array(items.prefix(limit)), forKey: key)
    }

    func remove(_ term: String) {
        defaults.set(all().filter { $0 != term }, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
