//
//  SeenFilmsLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SeenFilmsLocalDataSource: AnyObject {
    func loadSeenIDs() -> Set<Int>
    func saveSeenIDs(_ ids: Set<Int>)
    func loadHistoryEntries() -> [Int: SwipeHistoryEntry]
    func saveHistoryEntries(_ entries: [Int: SwipeHistoryEntry])
}

final class UserDefaultsSeenFilmsDataSource: SeenFilmsLocalDataSource {

    private let userIDProvider: () -> String?
    private let defaults: UserDefaults
    private let lock = NSLock()

    private var resolvedUserID: String {
        userIDProvider() ?? "local"
    }

    private var defaultsKey: String {
        "com.nurtore.movter.seenFilms.\(resolvedUserID)"
    }

    private var swipeHistoryKey: String {
        "com.nurtore.movter.swipeHistory.\(resolvedUserID)"
    }

    private var swipeHistoryMigratedKey: String {
        "com.nurtore.movter.swipeHistoryMigrated.\(resolvedUserID)"
    }

    init(
        defaults: UserDefaults = .standard,
        userIDProvider: @escaping () -> String? = { nil }
    ) {
        self.defaults = defaults
        self.userIDProvider = userIDProvider
    }

    func loadSeenIDs() -> Set<Int> {
        lock.withLock {
            if defaults.object(forKey: defaultsKey) != nil {
                return Set(defaults.array(forKey: defaultsKey) as? [Int] ?? [])
            }
            if defaults.data(forKey: swipeHistoryKey) != nil {
                return Set(loadHistoryEntriesUnlocked().keys)
            }
            return []
        }
    }

    func saveSeenIDs(_ ids: Set<Int>) {
        lock.withLock {
            let existingEntries = loadHistoryEntriesUnlocked()
            var updatedEntries: [Int: SwipeHistoryEntry] = [:]
            for id in ids where id > 0 {
                updatedEntries[id] = existingEntries[id] ?? SwipeHistoryEntry(
                    tmdbID: id,
                    lastDirection: .like,
                    updatedAt: Date(timeIntervalSince1970: 0),
                    passCount: 0
                )
            }
            defaults.set(Array(ids).sorted(), forKey: defaultsKey)
            persistEntriesUnlocked(updatedEntries)
            defaults.set(true, forKey: swipeHistoryMigratedKey)
        }
    }

    func loadHistoryEntries() -> [Int: SwipeHistoryEntry] {
        lock.withLock {
            loadHistoryEntriesUnlocked()
        }
    }

    func saveHistoryEntries(_ entries: [Int: SwipeHistoryEntry]) {
        lock.withLock {
            persistEntriesUnlocked(entries)
            defaults.set(entries.keys.sorted(), forKey: defaultsKey)
            defaults.set(true, forKey: swipeHistoryMigratedKey)
        }
    }

    private func loadHistoryEntriesUnlocked() -> [Int: SwipeHistoryEntry] {
        var entries: [Int: SwipeHistoryEntry] = [:]
        let historyData = defaults.data(forKey: swipeHistoryKey)

        if let historyData {
            if let decodedArray = try? JSONDecoder().decode([SwipeHistoryEntry].self, from: historyData) {
                for entry in decodedArray where entry.tmdbID > 0 {
                    entries[entry.tmdbID] = entry
                }
            } else if let decodedDictionary = try? JSONDecoder().decode([Int: SwipeHistoryEntry].self, from: historyData) {
                for (id, entry) in decodedDictionary where id > 0 && entry.tmdbID > 0 {
                    entries[id] = entry
                }
            }
        }

        let hasMigrated = defaults.bool(forKey: swipeHistoryMigratedKey)
        if !hasMigrated, let legacyIDs = defaults.array(forKey: defaultsKey) as? [Int] {
            var didMigrate = false
            for id in legacyIDs where id > 0 && entries[id] == nil {
                entries[id] = SwipeHistoryEntry(
                    tmdbID: id,
                    lastDirection: .like,
                    updatedAt: Date(timeIntervalSince1970: 0),
                    passCount: 0
                )
                didMigrate = true
            }
            defaults.set(true, forKey: swipeHistoryMigratedKey)
            if didMigrate || historyData == nil {
                persistEntriesUnlocked(entries)
            }
        }

        return entries
    }

    private func persistEntriesUnlocked(_ entries: [Int: SwipeHistoryEntry]) {
        let sortedEntries = entries.values.sorted { $0.tmdbID < $1.tmdbID }
        guard let encoded = try? JSONEncoder().encode(sortedEntries) else { return }
        defaults.set(encoded, forKey: swipeHistoryKey)
    }
}

