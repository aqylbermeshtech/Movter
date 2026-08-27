//
//  RecentSearchesStore.swift
//  Movter
//
//  Created by Nurtore on 27.08.2026.
//

import Foundation

/// The handful of most recent film queries, newest first, persisted in `UserDefaults`.
/// Small and non-sensitive, so it isn't scoped per account the way the watchlist stores
/// are — a shared device shows the same recents to everyone signed in on it.
enum RecentSearchesStore {

    private static let key = "recent_searches"
    private static let limit = 8

    static func all() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// Moves an existing term back to the top rather than duplicating it, and trims the
    /// list to `limit`.
    static func add(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var items = all().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        items.insert(trimmed, at: 0)
        UserDefaults.standard.set(Array(items.prefix(limit)), forKey: key)
    }

    static func remove(_ term: String) {
        UserDefaults.standard.set(all().filter { $0 != term }, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
