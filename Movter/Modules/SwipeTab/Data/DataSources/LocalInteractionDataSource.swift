//
//  LocalInteractionDataSource.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

protocol LocalInteractionDataSource: AnyObject {
    func recordInteraction(_ interaction: LocalSwipeInteraction)
    func loadRecentInteractions(limit: Int) -> [LocalSwipeInteraction]
    func clearInteractions()
}

final class UserDefaultsInteractionDataSource: LocalInteractionDataSource {
    private let defaults: UserDefaults
    private let storageKey = "com.nurtore.movter.pfedrec.local_interactions"
    private let maxBufferCount = 100
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordInteraction(_ interaction: LocalSwipeInteraction) {
        lock.lock()
        defer { lock.unlock() }

        var list = loadInternal()
        list.append(interaction)
        if list.count > maxBufferCount {
            list.removeFirst(list.count - maxBufferCount)
        }
        saveInternal(list)
    }

    func loadRecentInteractions(limit: Int) -> [LocalSwipeInteraction] {
        lock.lock()
        defer { lock.unlock() }

        let all = loadInternal()
        let count = min(limit, all.count)
        return Array(all.suffix(count))
    }

    func clearInteractions() {
        lock.lock()
        defer { lock.unlock() }

        defaults.removeObject(forKey: storageKey)
    }

    private func loadInternal() -> [LocalSwipeInteraction] {
        guard let data = defaults.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([LocalSwipeInteraction].self, from: data) else {
            return []
        }
        return list
    }

    private func saveInternal(_ list: [LocalSwipeInteraction]) {
        if let data = try? JSONEncoder().encode(list) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
