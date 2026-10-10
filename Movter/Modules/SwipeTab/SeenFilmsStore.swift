//
//  SeenFilmsStore.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation
import FirebaseAuth

/// Every film the user has swiped, either direction — not just likes. `/movie/popular`
/// is refetched from page 1 on every launch, and TMDB's own ranking can shift a title
/// from one page to another mid-session, so the deck needs its own record of what's
/// already been shown rather than relying on the (likes-only) watchlist.
protocol SeenFilmsStoring: AnyObject {
    /// Completion-based even though `UserDefaults` answers synchronously: it keeps this
    /// protocol consistent with `WatchlistStoring`/`ReviewStoring`, and free to move to
    /// a real backend later without changing call sites.
    func fetchIDs(completion: @escaping (Set<Int>) -> Void)
    /// Fire-and-forget: unlike a file write, a `UserDefaults` write has no failure mode
    /// worth reporting back to the caller.
    func markSeen(_ tmdbID: Int)
}

enum SeenFilmsStoreFactory {
    static func makeStore() -> SeenFilmsStoring {
        LocalSeenFilmsStore()
    }
}

/// A flat `Set<Int>` in `UserDefaults`, dynamic key per active account so switching accounts
/// never exposes or pollutes swipe history.
final class LocalSeenFilmsStore: SeenFilmsStoring {

    private let userIDProvider: () -> String?
    private let defaults = UserDefaults.standard

    private var defaultsKey: String {
        let userID = userIDProvider() ?? "local"
        return "com.nurtore.movter.seenFilms.\(userID)"
    }

    init(userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.userIDProvider = userIDProvider
    }

    convenience init(userID: String?) {
        self.init(userIDProvider: { userID })
    }

    func fetchIDs(completion: @escaping (Set<Int>) -> Void) {
        completion(readIDs())
    }

    func markSeen(_ tmdbID: Int) {
        var ids = readIDs()
        guard ids.insert(tmdbID).inserted else { return }
        defaults.set(Array(ids), forKey: defaultsKey)
    }

    private func readIDs() -> Set<Int> {
        Set(defaults.array(forKey: defaultsKey) as? [Int] ?? [])
    }
}
