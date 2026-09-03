//
//  WatchedFilmsStore.swift
//  Movter
//
//  Created by Nurtore on 03.09.2026.
//

import Foundation
import FirebaseAuth

/// Films the user says they have actually watched.
///
/// Deliberately not `SeenFilmsStoring`, which records every card the swipe deck has
/// shown — including the ones swiped away. That set answers "don't deal me this again";
/// this one answers "I've seen this film", and only the second is worth counting.
protocol WatchedFilmsStoring: AnyObject {
    /// Completion-based even though `UserDefaults` answers synchronously, matching the
    /// other stores so this can move to a backend without changing call sites.
    func fetchIDs(completion: @escaping (Set<Int>) -> Void)
    /// Both directions: unlike a swipe, marking a film watched is something the user
    /// can take back.
    func setWatched(_ isWatched: Bool, tmdbID: Int)
}

enum WatchedFilmsStoreFactory {
    static func makeStore() -> WatchedFilmsStoring {
        LocalWatchedFilmsStore(userID: Auth.auth().currentUser?.uid)
    }
}

/// A flat `Set<Int>` in `UserDefaults`, one key per account — the same shape and for the
/// same reason as `LocalSeenFilmsStore`.
final class LocalWatchedFilmsStore: WatchedFilmsStoring {

    private let defaultsKey: String
    private let defaults = UserDefaults.standard

    init(userID: String?) {
        self.defaultsKey = "com.nurtore.movter.watchedFilms.\(userID ?? "local")"
    }

    func fetchIDs(completion: @escaping (Set<Int>) -> Void) {
        completion(readIDs())
    }

    func setWatched(_ isWatched: Bool, tmdbID: Int) {
        var ids = readIDs()
        let changed = isWatched ? ids.insert(tmdbID).inserted : ids.remove(tmdbID) != nil
        guard changed else { return }
        defaults.set(Array(ids), forKey: defaultsKey)
    }

    private func readIDs() -> Set<Int> {
        Set(defaults.array(forKey: defaultsKey) as? [Int] ?? [])
    }
}
